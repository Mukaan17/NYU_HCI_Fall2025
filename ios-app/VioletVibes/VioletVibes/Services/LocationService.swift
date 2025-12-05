//
//  LocationService.swift
//  VioletVibes
//

import Foundation
import CoreLocation
import Observation

@Observable
final class LocationService: NSObject {
    static let shared = LocationService()
    
    private var locationManager: CLLocationManager
    
    var location: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var error: Error?
    
    private var locationUpdateTask: Task<Void, Never>?
    private var permissionContinuation: CheckedContinuation<Bool, Never>?
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters // Reduced from Best to save battery
        locationManager.pausesLocationUpdatesAutomatically = true // Allow pausing to save battery
        locationManager.distanceFilter = 50 // Only update if moved 50+ meters
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // Completely reset the location manager (useful when app restarts)
    @MainActor
    func resetLocationManager() {
        print("🔄 LocationService: Resetting location manager...")
        // Stop all updates
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        
        // Clear state
        location = nil
        error = nil
        
        // Recreate location manager to ensure clean state
        locationManager = CLLocationManager()
        setupLocationManager()
        
        // Re-check authorization status
        authorizationStatus = locationManager.authorizationStatus
        print("📍 LocationService: Location manager reset, authorization: \(authorizationStatus.rawValue)")
    }
    
    // Ensure delegate is always set (called when app becomes active)
    @MainActor
    func ensureDelegate() {
        if locationManager.delegate !== self {
            locationManager.delegate = self
        }
    }
    
    // Ensure main actor access for location updates
    @MainActor
    func updateLocation(_ newLocation: CLLocation) {
        self.location = newLocation
    }
    
    @MainActor
    func updateAuthorizationStatus(_ status: CLAuthorizationStatus) {
        self.authorizationStatus = status
    }
    
    // MARK: - Permissions
    @MainActor
    func checkPermissionStatus() async -> Bool {
        // Only check current status, don't request
        let currentStatus = locationManager.authorizationStatus
        authorizationStatus = currentStatus
        return currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways
    }
    
    @MainActor
    func requestPermission() async -> Bool {
        // Always check current status from location manager (not cached)
        let currentStatus = locationManager.authorizationStatus
        authorizationStatus = currentStatus
        
        // If already determined, return immediately
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
    @MainActor
    func startLocationUpdates() {
        print("📍 LocationService: Starting location updates, authorization status: \(authorizationStatus.rawValue)")
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("⚠️ LocationService: Not authorized, cannot start updates")
            return
        }
        
        // Stop any existing updates first to ensure clean restart
        locationManager.stopUpdatingLocation()
        
        // Ensure delegate is set (in case it was lost)
        if locationManager.delegate !== self {
            locationManager.delegate = self
        }
        
        // Only start continuous updates - don't call requestLocation() as it causes duplicate updates
        // The distance filter (50m) will ensure we only get updates when moved significantly
        locationManager.startUpdatingLocation()
        print("📍 LocationService: Location updates started (distance filter: 50m, accuracy: 100m)")
    }
    
    // Force a fresh location request (useful when app restarts)
    @MainActor
    func requestFreshLocation() {
        print("📍 LocationService: Requesting fresh location...")
        
        // Check authorization status directly from location manager
        let currentStatus = locationManager.authorizationStatus
        authorizationStatus = currentStatus
        
        guard currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways else {
            print("⚠️ LocationService: Not authorized for fresh location request (status: \(currentStatus.rawValue))")
            return
        }
        
        // Ensure delegate is set
        ensureDelegate()
        
        // Only request a one-time location update - don't start continuous updates here
        // This prevents duplicate location streams
        locationManager.requestLocation()
    }
    
    @MainActor
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationUpdateTask?.cancel()
    }
    
    @MainActor
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
    @MainActor
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Throttle location updates - only update if location changed significantly
        if let lastLocation = self.location {
            let distance = location.distance(from: lastLocation)
            // Only update if moved more than 25 meters (reduced from 50m to balance accuracy and performance)
            guard distance > 25 else {
                return
            }
        }
        
        print("📍 LocationService: Received location update: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        // Direct assignment since we're already on MainActor
        self.location = location
    }
    
    @MainActor
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ LocationService: Location error: \(error.localizedDescription)")
        // Direct assignment since we're already on MainActor
        self.error = error
    }
    
    @MainActor
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus
        self.authorizationStatus = newStatus
        
        // Resume permission continuation if waiting (only if still set to prevent double resume)
        if let continuation = self.permissionContinuation {
            self.permissionContinuation = nil
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

