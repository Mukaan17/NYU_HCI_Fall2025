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
        
        // Clear any stale location to force fresh fetch
        location = nil
        
        // Ensure delegate is set (in case it was lost)
        if locationManager.delegate !== self {
            locationManager.delegate = self
        }
        
        // Get initial location
        print("📍 LocationService: Requesting location...")
        locationManager.requestLocation()
        
        // Start continuous updates with distance filter (already set in setupLocationManager)
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
        
        // Stop any existing updates
        locationManager.stopUpdatingLocation()
        
        // Request fresh location
        print("📍 LocationService: Calling requestLocation() and startUpdatingLocation()")
        locationManager.requestLocation()
        locationManager.startUpdatingLocation()
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
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("📍 LocationService: Received location update: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        // Update on main thread immediately
        DispatchQueue.main.async { [weak self] in
            self?.location = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ LocationService: Location error: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.error = error
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.authorizationStatus = newStatus
            
            // Resume permission continuation if waiting (only if still set to prevent double resume)
            if let continuation = self.permissionContinuation {
                self.permissionContinuation = nil
                let isAuthorized = newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways
                continuation.resume(returning: isAuthorized)
            }
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

