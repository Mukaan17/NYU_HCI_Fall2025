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
    var steps: [StepInstruction] = []
    var mapsLink: String? = nil
    var isLoadingRoute: Bool = false
    
    private let apiService = APIService.shared
    
    private let defaultLat = 40.693393
    private let defaultLng = -73.98555
    
    private var lastLocationUpdate: Date?
    private let locationUpdateThrottle: TimeInterval = 2.0
    
    init() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: defaultLat, longitude: defaultLng),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        cameraPosition = .region(region)
    }
    
    func updateRegion(latitude: Double, longitude: Double, animated: Bool = true) {
        let now = Date()
        if let last = lastLocationUpdate, now.timeIntervalSince(last) < locationUpdateThrottle { return }
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
        lastLocationUpdate = nil
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            cameraPosition = .region(region)
        }
    }
    
    func fetchRoute(destinationLat: Double, destinationLng: Double) async {
        isLoadingRoute = true
        defer { isLoadingRoute = false }
        
        do {
            let response = try await apiService.getDirections(lat: destinationLat, lng: destinationLng)
            
            mapsLink = response.maps_link
            
            // polyline
            if let poly = response.polyline {
                polylineCoordinates = poly.compactMap { arr in
                    guard arr.count >= 2 else { return nil }
                    return CLLocationCoordinate2D(latitude: arr[0], longitude: arr[1])
                }
            } else {
                polylineCoordinates = []
            }
            
            // steps
            steps = response.steps ?? []
            
        } catch {
            print("Route error: \(error)")
            polylineCoordinates = []
            steps = []
            mapsLink = nil
        }
    }
    
    func clearRoute() {
        polylineCoordinates = []
        steps = []
        mapsLink = nil
    }
}
