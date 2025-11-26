//
//  LocationService.swift
//  VioletVibes
//

import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class LocationService: NSObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    
    var location: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var error: Error?
    
    private var locationUpdateTask: Task<Void, Never>?
    private var permissionContinuation: CheckedContinuation<Bool, Never>?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Permissions
    func requestPermission() async -> Bool {
        // If already determined, return immediately
        let currentStatus = authorizationStatus
        guard currentStatus == .notDetermined else {
            return currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways
        }
        
        // Cancel any existing continuation to prevent leaks
        if let oldContinuation = permissionContinuation {
            permissionContinuation = nil
            oldContinuation.resume(returning: false)
        }
        
        locationManager.requestWhenInUseAuthorization()
        
        // Wait for authorization status update with timeout
        return await withCheckedContinuation { continuation in
            permissionContinuation = continuation
            
            // Set up timeout to ensure continuation is always resumed
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 second timeout
                
                // If continuation still exists, resume it with current status
                if let cont = self.permissionContinuation {
                    self.permissionContinuation = nil
                    let status = self.authorizationStatus
                    cont.resume(returning: status == .authorizedWhenInUse || status == .authorizedAlways)
                }
                }
        }
    }
    
    // MARK: - Location Updates
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        
        // Get initial location
        locationManager.requestLocation()
        
        // Start continuous updates
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationUpdateTask?.cancel()
    }
    
    func getCurrentLocation() async throws -> CLLocation {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            throw LocationError.notAuthorized
        }
        
        locationManager.requestLocation()
        
        // Wait for location update with timeout
        return try await withCheckedThrowingContinuation { continuation in
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                if !Task.isCancelled {
                    continuation.resume(throwing: LocationError.timeout)
                }
            }
            
            // Poll for location
            Task {
                while !Task.isCancelled {
                    if let currentLocation = location {
                        timeoutTask.cancel()
                        continuation.resume(returning: currentLocation)
                        break
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                }
            }
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = error
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus
        authorizationStatus = newStatus
        
        // Resume permission continuation if waiting (only if still set to prevent double resume)
        if let continuation = permissionContinuation {
            permissionContinuation = nil
            let isAuthorized = newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways
            continuation.resume(returning: isAuthorized)
        }
    }
}

enum LocationError: LocalizedError {
    case notAuthorized
    case timeout
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Location permission not granted"
        case .timeout:
            return "Location request timed out"
        case .unknown:
            return "Unknown location error"
        }
    }
}

