//
//  LocationService.swift
//  VioletVibes
//

import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var error: Error?
    
    private var locationUpdateTask: Task<Void, Never>?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Permissions
    func requestPermission() async -> Bool {
        guard authorizationStatus == .notDetermined else {
            return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
        }
        
        locationManager.requestWhenInUseAuthorization()
        
        // Wait for authorization status update
        return await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = $authorizationStatus
                .dropFirst()
                .sink { status in
                    continuation.resume(returning: status == .authorizedWhenInUse || status == .authorizedAlways)
                    cancellable?.cancel()
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
        
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = $location
                .compactMap { $0 }
                .first()
                .sink { location in
                    continuation.resume(returning: location)
                    cancellable?.cancel()
                }
            
            locationManager.requestLocation()
            
            // Timeout after 10 seconds
            Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                if !Task.isCancelled {
                    cancellable?.cancel()
                    continuation.resume(throwing: LocationError.timeout)
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
        authorizationStatus = manager.authorizationStatus
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

