//
//  LocationManager.swift
//  VioletVibes
//

import Foundation
import CoreLocation
import SwiftUI

class LocationManager: ObservableObject {
    @Published var location: CLLocation?
    @Published var loading: Bool = true
    @Published var error: String?
    
    private let locationService = LocationService.shared
    
    init() {
        setupLocationUpdates()
    }
    
    private func setupLocationUpdates() {
        // Observe location service updates
        Task {
            for await location in locationService.$location.values {
                await MainActor.run {
                    self.location = location
                    if location != nil {
                        self.loading = false
                    }
                }
            }
        }
        
        // Request permission and start updates
        Task {
            let authorized = await locationService.requestPermission()
            if authorized {
                locationService.startLocationUpdates()
            } else {
                await MainActor.run {
                    self.error = "Location permission not granted"
                    self.loading = false
                }
            }
        }
    }
    
    var coordinate: CLLocationCoordinate2D? {
        location?.coordinate
    }
}

