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
    var forecast: [HourlyForecast]?
    var isLoading: Bool = false
    
    @MainActor private var currentWeatherTask: Task<Weather?, Never>?
    @MainActor private var currentForecastTask: Task<[HourlyForecast]?, Never>?
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
        self.isLoading = true
        
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
            self.isLoading = false
            print("✅ WeatherManager: Weather loaded successfully: \(weather.temp)°F \(weather.emoji)")
            
            // Preload forecast in the background (don't wait for it)
            Task {
                await self.loadForecast(locationManager: locationManager, timeout: 1.0)
            }
        } else {
            self.isLoading = false
            print("⚠️ WeatherManager: Weather loading failed - no weather data available")
        }
    }
    
    // Load forecast data
    @MainActor
    func loadForecast(locationManager: LocationManager, timeout: Double = 1.0) async {
        // Cancel previous task
        currentForecastTask?.cancel()
        
        // If forecast already exists and is recent, skip loading
        if forecast != nil {
            print("🌤️ WeatherManager: Forecast already loaded, skipping")
            return
        }
        
        print("🌤️ WeatherManager: Loading forecast with timeout (\(timeout)s)...")
        
        // Use location from locationManager directly if available (faster)
        // Otherwise wait briefly for it
        let location: CLLocation?
        if let existingLocation = locationManager.location {
            location = existingLocation
        } else {
            // Brief wait for location
            func waitForLocation() async -> CLLocation? {
                let startTime = Date()
                while Date().timeIntervalSince(startTime) < timeout {
                    if let loc = locationManager.location {
                        return loc
                    }
                    if !locationManager.loading && locationManager.location == nil {
                        return nil
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                }
                return nil
            }
            location = await waitForLocation()
        }
        
        if let location = location {
            print("📍 WeatherManager: Got location, loading forecast: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            let forecastData = await weatherService.getForecast(
                lat: location.coordinate.latitude,
                lon: location.coordinate.longitude
            )
            
            if let forecast = forecastData {
                self.forecast = forecast
                print("✅ WeatherManager: Forecast loaded successfully: \(forecast.count) hours")
            } else {
                print("⚠️ WeatherManager: Forecast loading failed")
            }
        } else {
            // Try fallback location immediately
            let fallbackLat = 40.693393
            let fallbackLon = -73.98555
            print("🌤️ WeatherManager: Loading fallback forecast for: \(fallbackLat), \(fallbackLon)")
            let forecastData = await weatherService.getForecast(
                lat: fallbackLat,
                lon: fallbackLon
            )
            
            if let forecast = forecastData {
                self.forecast = forecast
                print("✅ WeatherManager: Fallback forecast loaded: \(forecast.count) hours")
            }
        }
    }
}

