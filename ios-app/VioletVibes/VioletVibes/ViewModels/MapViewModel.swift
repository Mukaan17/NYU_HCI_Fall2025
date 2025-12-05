//
//  MapViewModel.swift
//  VioletVibes
//

import Foundation
import MapKit
import SwiftUI
import Observation

@Observable
final class MapViewModel {
    var cameraPosition: MapCameraPosition
    var polylineCoordinates: [CLLocationCoordinate2D] = []
    var routeSteps: [RouteStep] = []
    var routeMode: String? = nil // "walking" or "transit"
    var routeDuration: String? = nil
    var routeDistance: String? = nil
    var isLoadingRoute: Bool = false
    var isNavigating: Bool = false
    var navigationDestination: CLLocationCoordinate2D? = nil
    var shouldFitRoute: Bool = true // Control whether route calculation should adjust camera
    
    private let apiService = APIService.shared
    
    // NYU Tandon default
    private let defaultLat = 40.693393
    private let defaultLng = -73.98555
    
    // Track last update to prevent excessive updates
    private var lastLocationUpdate: Date?
    private let locationUpdateThrottle: TimeInterval = 2.0 // Update at most every 2 seconds
    
    init() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: defaultLat, longitude: defaultLng),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        cameraPosition = .region(region)
    }
    
    func updateRegion(latitude: Double, longitude: Double, animated: Bool = true) {
        // Throttle location updates to improve performance
        let now = Date()
        if let lastUpdate = lastLocationUpdate,
           now.timeIntervalSince(lastUpdate) < locationUpdateThrottle {
            return
        }
        lastLocationUpdate = now
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        if animated {
            withAnimation(.easeInOut(duration: 0.5)) {
                cameraPosition = .region(region)
            }
        } else {
            cameraPosition = .region(region)
        }
    }
    
    func centerToUserLocation(latitude: Double, longitude: Double) {
        // Clear any throttling to ensure immediate update
        lastLocationUpdate = nil
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        // Always update, bypassing throttling for manual button presses
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            cameraPosition = .region(region)
        }
    }
    
    func zoomToLocation(latitude: Double, longitude: Double, animated: Bool = true) {
        // Clear throttling for immediate zoom
        lastLocationUpdate = nil
        
        // Offset center downward (decrease latitude) so pin appears above the card
        // By moving the map center south, the pin (at the original latitude) appears higher on screen
        let offsetLatitude = latitude - 0.0005 // Offset by ~55 meters south to position pin above card
        
        // Use smaller span for zoomed-in view
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: offsetLatitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        
        if animated {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                cameraPosition = .region(region)
            }
        } else {
            cameraPosition = .region(region)
        }
    }
    
    func fetchRoute(originLat: Double? = nil, originLng: Double? = nil, destinationLat: Double, destinationLng: Double) async {
        isLoadingRoute = true
        
        do {
            let response = try await apiService.getDirections(
                lat: destinationLat,
                lng: destinationLng,
                originLat: originLat,
                originLng: originLng
            )
            
            if let polyline = response.polyline {
                let coordinates = polyline.compactMap { point -> CLLocationCoordinate2D? in
                    guard point.count >= 2 else { return nil }
                    return CLLocationCoordinate2D(latitude: point[0], longitude: point[1])
                }
                
                await MainActor.run {
                    polylineCoordinates = coordinates
                    routeMode = response.mode
                    routeDuration = response.duration_text
                    routeDistance = response.distance_text
                    isLoadingRoute = false
                    
                    // Update camera to show entire route only if shouldFitRoute is true
                    if !coordinates.isEmpty && shouldFitRoute {
                        updateCameraToFitRoute(coordinates: coordinates)
                    }
                }
            } else {
                // Fallback: Use MapKit's native directions if backend polyline fails
                await fetchRouteWithMapKit(originLat: originLat, originLng: originLng, destinationLat: destinationLat, destinationLng: destinationLng)
            }
        } catch {
            print("Route error: \(error)")
            // Fallback to MapKit native directions
            await fetchRouteWithMapKit(originLat: originLat, originLng: originLng, destinationLat: destinationLat, destinationLng: destinationLng)
        }
    }
    
    // Fallback: Use MapKit's native MKDirections for route rendering
    private func fetchRouteWithMapKit(originLat: Double?, originLng: Double?, destinationLat: Double, destinationLng: Double) async {
        let originCoordinate: CLLocationCoordinate2D
        if let lat = originLat, let lng = originLng {
            originCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        } else {
            // Default to NYU Tandon
            originCoordinate = CLLocationCoordinate2D(latitude: 40.693393, longitude: -73.98555)
        }
        
        let destinationCoordinate = CLLocationCoordinate2D(latitude: destinationLat, longitude: destinationLng)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: originCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
        request.transportType = .walking // Start with walking, can be enhanced to try transit too
        
        let directions = MKDirections(request: request)
        
        do {
            let response = try await directions.calculate()
            
            if let route = response.routes.first {
                let coordinates = route.polyline.coordinates
                
                await MainActor.run {
                    polylineCoordinates = coordinates
                    routeMode = "walking"
                    isLoadingRoute = false
                    
                    // Update camera to show entire route only if shouldFitRoute is true
                    if !coordinates.isEmpty && shouldFitRoute {
                        updateCameraToFitRoute(coordinates: coordinates)
                    }
                }
            } else {
                await MainActor.run {
                    polylineCoordinates = []
                    isLoadingRoute = false
                }
            }
        } catch {
            print("MapKit directions error: \(error)")
            await MainActor.run {
                polylineCoordinates = []
                isLoadingRoute = false
            }
        }
    }
    
    // Update camera to fit the entire route
    private func updateCameraToFitRoute(coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else { return }
        
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLng = coordinates.map { $0.longitude }.min() ?? 0
        let maxLng = coordinates.map { $0.longitude }.max() ?? 0
        
        let centerLat = (minLat + maxLat) / 2
        let centerLng = (minLng + maxLng) / 2
        let latDelta = max(maxLat - minLat, 0.01) * 1.3 // Add 30% padding
        let lngDelta = max(maxLng - minLng, 0.01) * 1.3
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        )
        
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(region)
        }
    }
    
    func clearRoute() {
        polylineCoordinates = []
        routeSteps = []
        routeMode = nil
        routeDuration = nil
        routeDistance = nil
        isNavigating = false
        navigationDestination = nil
    }
    
    // Start navigation mode - switches camera to follow user location
    func startNavigation(destination: CLLocationCoordinate2D, userLocation: CLLocationCoordinate2D) {
        isNavigating = true
        navigationDestination = destination
        
        // Use MapCamera with heading and pitch for true navigation view
        let camera = MapCamera(
            centerCoordinate: userLocation,
            distance: 500, // Close distance for navigation (in meters)
            heading: 0, // Will be updated based on user's course
            pitch: 60 // Angled view like Apple Maps navigation
        )
        
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .camera(camera)
        }
    }
    
    // Stop navigation mode
    func stopNavigation() {
        isNavigating = false
        navigationDestination = nil
    }
    
    // Update navigation camera to follow user location with heading
    func updateNavigationCamera(userLocation: CLLocationCoordinate2D, heading: Double? = nil) {
        guard isNavigating else { return }
        
        // Use MapCamera with heading for navigation view
        let camera = MapCamera(
            centerCoordinate: userLocation,
            distance: 500, // Close distance for navigation
            heading: heading ?? 0, // Use user's course/heading if available
            pitch: 60 // Angled view
        )
        
        // Update camera to follow user (no animation for smooth following)
        cameraPosition = .camera(camera)
    }
}

// Helper extension to extract coordinates from MKPolyline
extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords: [CLLocationCoordinate2D] = []
        let pointCount = pointCount
        let points = self.points()
        
        for i in 0..<pointCount {
            coords.append(points[i].coordinate)
        }
        
        return coords
    }
}

// Route step model for displaying route instructions
struct RouteStep: Identifiable {
    let id = UUID()
    let instruction: String
    let distance: String?
    let duration: String?
}

