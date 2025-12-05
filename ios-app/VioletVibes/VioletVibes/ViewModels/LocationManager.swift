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
    private var locationUpdateTask: Task<Void, Never>?
    @MainActor private var isSettingUp: Bool = false
    
    init() {
        // Set a timeout to stop loading if location never arrives
        Task {
            // Wait 10 seconds, then stop loading if still no location
            try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
            await MainActor.run {
                if self.loading && self.location == nil {
                    print("⚠️ LocationManager: Initial timeout - stopping loading state")
                    self.loading = false
                }
            }
        }
        Task { @MainActor in
            setupLocationUpdates()
        }
    }
    
    // Restart location updates (useful when app comes to foreground)
    func restartLocationUpdates() {
        print("🔄 LocationManager: Restarting location updates...")
        locationUpdateTask?.cancel()
        
        Task { @MainActor in
            // Reset state when restarting - don't rely on cached location
            self.location = nil
            self.loading = true
            self.error = nil
            
            // Immediately restart setup - don't wait
            self.setupLocationUpdates()
        }
    }
    
    // Swift 6.2: Force location check with structured concurrency
    func forceLocationCheck() {
        Task { @MainActor in
            print("🔄 LocationManager: Force location check called")
            
            // Check if setup is already in progress
            if isSettingUp {
                print("📍 LocationManager: Setup already in progress, skipping force check")
                return
            }
            
            // Ensure delegate is set
            await self.locationService.ensureDelegate()
            
            // Check if we already have location from LocationService
            if let currentLocation = self.locationService.location {
                print("📍 LocationManager: Found location in LocationService: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")
                self.location = currentLocation
                self.loading = false
                return
            }
            
            // Small delay to allow any pending location updates
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // If we're stuck loading or have no location, force a restart
            if (self.loading && self.location == nil) || self.location == nil {
                print("🔄 LocationManager: No location found, restarting location updates")
                // Cancel any existing task
                self.locationUpdateTask?.cancel()
                // Reset state
                self.location = nil
                self.loading = true
                self.error = nil
                // Restart - but don't reset LocationService, just restart updates
                self.setupLocationUpdates()
            }
        }
    }
    
    @MainActor
    private func setupLocationUpdates() {
        // Swift 6.2: Use TaskGroup to ensure atomic check-and-set
        Task { @MainActor in
            guard !isSettingUp else {
                print("📍 LocationManager: Setup already in progress, skipping")
                return
            }
            
            isSettingUp = true
            defer { isSettingUp = false }
            
            print("📍 LocationManager: Setting up location updates...")
            
            // Ensure delegate is set first
            await locationService.ensureDelegate()
            
            // Only check permission status, don't request (permissions should only be requested on permissions screen)
            let authorized = await locationService.checkPermissionStatus()
            print("📍 LocationManager: Permission status: \(authorized)")
            
            if authorized {
                // Start location updates (this will handle continuous updates)
                locationService.startLocationUpdates()
                
                // Request initial location (one-time, doesn't start continuous updates)
                await locationService.requestFreshLocation()
                
                // Swift 6.2: Use structured polling with timeout (reduced frequency)
                locationUpdateTask = Task { @MainActor in
                    let maxPollingTime: UInt64 = 10_000_000_000 // 10 seconds (increased timeout)
                    let pollInterval: UInt64 = 1_000_000_000 // 1 second (reduced polling frequency)
                    var attempts = 0
                    let maxAttempts = Int(maxPollingTime / pollInterval) // 10 attempts
                    
                    // Create a timeout task that we can cancel
                    let timeoutTask = Task {
                        try? await Task.sleep(nanoseconds: maxPollingTime)
                        await MainActor.run {
                            if self.location == nil && self.loading {
                                print("⚠️ LocationManager: Timeout waiting for location, stopping loading")
                                // Stop loading so UI doesn't stay stuck - weather will use fallback
                                self.loading = false
                            }
                        }
                    }
                    
                    // Poll for location updates (reduced frequency to save battery and CPU)
                    while !Task.isCancelled && attempts < maxAttempts {
                        if let newLocation = self.locationService.location {
                            // Always update if we don't have a location yet
                            if self.location == nil {
                                print("📍 LocationManager: Got first location: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
                                self.location = newLocation
                                self.loading = false
                                // Cancel timeout task since we got location
                                timeoutTask.cancel()
                                return
                            } else {
                                // Only update if location changed significantly (increased threshold to reduce view updates)
                                let currentLocation = self.location!
                                let distance = newLocation.distance(from: currentLocation)
                                if distance > 100 { // Increased from 50m to 100m to reduce updates
                                    print("📍 LocationManager: Location updated (moved \(Int(distance))m)")
                                    self.location = newLocation
                                }
                            }
                            if self.loading {
                                print("📍 LocationManager: Setting loading to false")
                                self.loading = false
                            }
                        }
                        
                        attempts += 1
                        if self.location != nil {
                            // We have location, cancel timeout and return
                            timeoutTask.cancel()
                            return
                        }
                        
                        // Poll interval (increased to reduce CPU usage)
                        try? await Task.sleep(nanoseconds: pollInterval)
                    }
                    
                    // If we exit the loop, cancel timeout task
                    timeoutTask.cancel()
                    
                    // Final check - stop loading if still no location
                    if self.location == nil && self.loading {
                        print("⚠️ LocationManager: Timeout waiting for location, stopping loading")
                        self.loading = false
                    }
                }
            } else {
                print("❌ LocationManager: Permission not granted")
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

