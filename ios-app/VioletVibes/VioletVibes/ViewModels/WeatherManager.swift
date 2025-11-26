//
//  WeatherManager.swift
//  VioletVibes
//

import Foundation
import CoreLocation
import SwiftUI
import Observation

@Observable
final class WeatherManager {
    var weather: Weather?
    
    @MainActor private var currentWeatherTask: Task<Weather?, Never>?
    @MainActor private var lastLoadTime: Date?
    private let cooldownInterval: TimeInterval = 0.5
    private let weatherService = WeatherService.shared
    
    // Swift 6.2: Load weather with debouncing and structured concurrency
    @MainActor
    func loadWeather(locationManager: LocationManager, timeout: Double = 2.0) async {
        // Cancel previous task using structured cancellation
        currentWeatherTask?.cancel()
        
        // Check cooldown atomically
        if let lastLoad = lastLoadTime, Date().timeIntervalSince(lastLoad) < cooldownInterval {
            print("🌤️ WeatherManager: Still in cooldown, skipping load")
            return // Still in cooldown
        }
        
        print("🌤️ WeatherManager: Loading weather with timeout (\(timeout)s)...")
        
        // Swift 6.2: Use async let for parallel execution
        async let locationWeatherTask: Weather? = {
            // Helper function to wait for location with timeout
            func waitForLocation() async -> CLLocation? {
                let startTime = Date()
                while Date().timeIntervalSince(startTime) < timeout {
                    if let location = locationManager.location {
                        return location
                    }
                    // Check if loading finished without location
                    if !locationManager.loading && locationManager.location == nil {
                        return nil
                    }
                    try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                }
                return nil
            }
            
            if let location = await waitForLocation() {
                print("📍 WeatherManager: Got location, loading weather: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                return await self.weatherService.getWeather(
                    lat: location.coordinate.latitude,
                    lon: location.coordinate.longitude
                )
            }
            return nil
        }()
        
        async let fallbackWeatherTask: Weather? = {
            let fallbackLat = 40.693393
            let fallbackLon = -73.98555
            print("🌤️ WeatherManager: Loading fallback weather for: \(fallbackLat), \(fallbackLon)")
            return await self.weatherService.getWeather(
                lat: fallbackLat,
                lon: fallbackLon
            )
        }()
        
        // Wait for both tasks, prioritize location-based if available
        let locationWeather = await locationWeatherTask
        let fallbackWeather = await fallbackWeatherTask
        let result = locationWeather ?? fallbackWeather
        
        // Update weather on main actor
        if let weather = result {
            self.weather = weather
            self.lastLoadTime = Date()
            print("✅ WeatherManager: Weather loaded successfully: \(weather.temp)°F \(weather.emoji)")
        } else {
            print("⚠️ WeatherManager: Weather loading failed - no weather data available")
        }
    }
}

