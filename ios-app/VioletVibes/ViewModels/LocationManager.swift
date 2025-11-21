//
//  LocationManager.swift
//  VioletVibes
//

import Foundation
import CoreLocation
import SwiftUI
import Observation

@Observable
final class LocationManager {
    var location: CLLocation?
    var loading: Bool = true
    var error: String?
    
    private let locationService = LocationService.shared
    
    init() {
        setupLocationUpdates()
    }
    
    private func setupLocationUpdates() {
        // Request permission and start updates
        Task { @MainActor in
            let authorized = await locationService.requestPermission()
            if authorized {
                locationService.startLocationUpdates()
                // Poll for location updates
                Task {
                    while !Task.isCancelled {
                        await MainActor.run {
                            if let newLocation = locationService.location {
                                self.location = newLocation
                                if self.loading {
                                    self.loading = false
                                }
                            }
                        }
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    }
                }
            } else {
                    self.error = "Location permission not granted"
                    self.loading = false
            }
        }
    }
    
    var coordinate: CLLocationCoordinate2D? {
        location?.coordinate
    }
}

