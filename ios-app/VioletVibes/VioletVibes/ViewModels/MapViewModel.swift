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
    var isLoadingRoute: Bool = false
    
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
    
    func fetchRoute(destinationLat: Double, destinationLng: Double) async {
            isLoadingRoute = true
        
        do {
            let response = try await apiService.getDirections(lat: destinationLat, lng: destinationLng)
            
            if let polyline = response.polyline {
                let coordinates = polyline.compactMap { point -> CLLocationCoordinate2D? in
                    guard point.count >= 2 else { return nil }
                    return CLLocationCoordinate2D(latitude: point[0], longitude: point[1])
                }
                
                polylineCoordinates = coordinates
                isLoadingRoute = false
            } else {
                polylineCoordinates = []
                isLoadingRoute = false
            }
        } catch {
            print("Route error: \(error)")
            polylineCoordinates = []
            isLoadingRoute = false
        }
    }
    
    func clearRoute() {
        polylineCoordinates = []
    }
}

