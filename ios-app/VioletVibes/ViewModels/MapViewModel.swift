//
//  MapViewModel.swift
//  VioletVibes
//

import Foundation
import MapKit
import SwiftUI

class MapViewModel: ObservableObject {
    @Published var region: MKCoordinateRegion
    @Published var polylineCoordinates: [CLLocationCoordinate2D] = []
    @Published var isLoadingRoute: Bool = false
    
    private let apiService = APIService.shared
    
    // NYU Tandon default
    private let defaultLat = 40.693393
    private let defaultLng = -73.98555
    
    init() {
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: defaultLat, longitude: defaultLng),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    func updateRegion(latitude: Double, longitude: Double) {
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    func fetchRoute(destinationLat: Double, destinationLng: Double) async {
        await MainActor.run {
            isLoadingRoute = true
        }
        
        do {
            let response = try await apiService.getDirections(lat: destinationLat, lng: destinationLng)
            
            if let polyline = response.polyline {
                let coordinates = polyline.compactMap { point -> CLLocationCoordinate2D? in
                    guard point.count >= 2 else { return nil }
                    return CLLocationCoordinate2D(latitude: point[0], longitude: point[1])
                }
                
                await MainActor.run {
                    self.polylineCoordinates = coordinates
                    self.isLoadingRoute = false
                }
            } else {
                await MainActor.run {
                    self.polylineCoordinates = []
                    self.isLoadingRoute = false
                }
            }
        } catch {
            print("Route error: \(error)")
            await MainActor.run {
                self.polylineCoordinates = []
                self.isLoadingRoute = false
            }
        }
    }
    
    func clearRoute() {
        polylineCoordinates = []
    }
}

