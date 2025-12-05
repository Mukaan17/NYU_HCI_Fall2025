//
//  WeatherService.swift
//  VioletVibes
//

import Foundation
import CoreLocation

actor WeatherService {
    static let shared = WeatherService()
    
    private init() {}
    
    func getWeather(lat: Double, lon: Double) async -> Weather? {
        guard let apiKey = getOpenWeatherKey() else {
            print("OpenWeather API key not found. Please add OPENWEATHER_KEY to Config.plist or environment variables.")
            return nil
        }
        
        let baseURL = "https://api.openweathermap.org/data/2.5/weather"
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "imperial")
        ]
        
        guard let url = urlComponents.url else {
            print("Invalid weather API URL")
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    print("Weather API error: HTTP \(httpResponse.statusCode)")
                    if let errorData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("API error response: \(errorData)")
                    }
                    return nil
                }
            }
            
            let decoder = JSONDecoder()
            let weatherModel = try decoder.decode(Weather.self, from: data)
            print("✅ Weather loaded: \(weatherModel.temp)°F \(weatherModel.emoji)")
            return weatherModel
        } catch {
            print("Weather fetch error: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func getOpenWeatherKey() -> String? {
        // Try environment variable first
        if let key = ProcessInfo.processInfo.environment["OPENWEATHER_KEY"], !key.isEmpty {
            print("🔑 Found OPENWEATHER_KEY from environment variable")
            return key
        }
        
        // Try Config.plist - Method 1: Using path
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist") {
            print("📄 Found Config.plist at path: \(path)")
            if let config = NSDictionary(contentsOfFile: path) {
                print("📋 Config.plist loaded successfully")
                if let key = config["OPENWEATHER_KEY"] as? String, !key.isEmpty {
                    print("🔑 Found OPENWEATHER_KEY in Config.plist: \(String(key.prefix(8)))...")
                    return key
                } else {
                    print("⚠️ OPENWEATHER_KEY not found in Config.plist or is empty")
                }
            } else {
                print("❌ Failed to load Config.plist as NSDictionary")
            }
        } else {
            print("❌ Config.plist not found in bundle")
            // Try alternative method using URL
            if let url = Bundle.main.url(forResource: "Config", withExtension: "plist") {
                print("📄 Found Config.plist at URL: \(url)")
                if let config = NSDictionary(contentsOf: url) {
                    print("📋 Config.plist loaded successfully via URL")
                    if let key = config["OPENWEATHER_KEY"] as? String, !key.isEmpty {
                        print("🔑 Found OPENWEATHER_KEY in Config.plist: \(String(key.prefix(8)))...")
                        return key
                    }
                }
            } else {
                print("❌ Config.plist not found in bundle (tried both path and URL methods)")
                print("💡 Make sure Config.plist is added to the target's 'Copy Bundle Resources' build phase")
            }
        }
        
        return nil
    }
    
    func getForecast(lat: Double, lon: Double) async -> [HourlyForecast]? {
        guard let apiKey = getOpenWeatherKey() else {
            print("OpenWeather API key not found. Please add OPENWEATHER_KEY to Config.plist or environment variables.")
            return nil
        }
        
        let baseURL = "https://api.openweathermap.org/data/2.5/forecast"
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "imperial")
        ]
        
        guard let url = urlComponents.url else {
            print("Invalid forecast API URL")
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    print("Forecast API error: HTTP \(httpResponse.statusCode)")
                    if let errorData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("API error response: \(errorData)")
                    }
                    return nil
                }
            }
            
            let decoder = JSONDecoder()
            let forecastResponse = try decoder.decode(ForecastResponse.self, from: data)
            
            // Convert to HourlyForecast array, filtering to show only future hours
            let now = Date()
            let forecasts = forecastResponse.list
                .filter { item in
                    let itemDate = Date(timeIntervalSince1970: item.dt)
                    return itemDate >= now
                }
                .prefix(24) // Limit to next 24 hours
                .map { item -> HourlyForecast in
                    let itemDate = Date(timeIntervalSince1970: item.dt)
                    let temp = Int(round(item.main.temp))
                    let weatherCondition = item.weather.first?.main ?? "Clear"
                    let emoji = weatherConditionToEmoji(weatherCondition)
                    let description = item.weather.first?.description.capitalized ?? "Clear"
                    let humidity = item.main.humidity
                    let windSpeed = item.wind?.speed
                    
                    return HourlyForecast(
                        time: itemDate,
                        temp: temp,
                        emoji: emoji,
                        description: description,
                        humidity: humidity,
                        windSpeed: windSpeed
                    )
                }
            
            print("✅ Forecast loaded: \(forecasts.count) hours")
            return Array(forecasts)
        } catch {
            print("Forecast fetch error: \(error.localizedDescription)")
            return nil
        }
    }
}

