//
//  WeatherService.swift
//  VioletVibes
//

import Foundation
import CoreLocation

actor WeatherService {
    static let shared = WeatherService()
    
    private let apiService = APIService.shared
    
    private init() {}
    
    func getWeather(lat: Double, lon: Double) async -> Weather? {
        // Get base URL from APIService
        let baseURL: String = await {
            if let apiURL = ProcessInfo.processInfo.environment["API_URL"], !apiURL.isEmpty {
                return apiURL
            } else if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
                      let config = NSDictionary(contentsOfFile: path),
                      let url = config["API_URL"] as? String,
                      !url.isEmpty {
                return url
            } else {
                return "http://localhost:5001"
            }
        }()
        
        var urlComponents = URLComponents(string: "\(baseURL)/api/weather")!
        urlComponents.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon))
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
    
    func getForecast(lat: Double, lon: Double) async -> [HourlyForecast]? {
        // Get base URL from APIService
        let baseURL: String = await {
            if let apiURL = ProcessInfo.processInfo.environment["API_URL"], !apiURL.isEmpty {
                return apiURL
            } else if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
                      let config = NSDictionary(contentsOfFile: path),
                      let url = config["API_URL"] as? String,
                      !url.isEmpty {
                return url
            } else {
                return "http://localhost:5001"
            }
        }()
        
        var urlComponents = URLComponents(string: "\(baseURL)/api/weather/forecast")!
        urlComponents.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon))
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
            
            // Parse backend response format
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            guard let forecastList = json?["forecast"] as? [[String: Any]] else {
                print("Invalid forecast response format")
                return nil
            }
            
            // Convert backend format to HourlyForecast array
            let now = Date()
            let forecasts = forecastList
                .compactMap { item -> HourlyForecast? in
                    guard let dt = item["dt"] as? TimeInterval else { return nil }
                    let itemDate = Date(timeIntervalSince1970: dt)
                    
                    // Only include future hours
                    guard itemDate >= now else { return nil }
                    
                    let main = item["main"] as? [String: Any] ?? [:]
                    let weatherArray = item["weather"] as? [[String: Any]] ?? []
                    let weather = weatherArray.first ?? [:]
                    let wind = item["wind"] as? [String: Any] ?? [:]
                    
                    let temp = Int(round(main["temp"] as? Double ?? 0))
                    let weatherCondition = (weather["main"] as? String ?? "Clear").lowercased()
                    let emoji = weatherConditionToEmoji(weatherCondition)
                    let description = (weather["description"] as? String ?? "Clear").capitalized
                    let humidity = main["humidity"] as? Int ?? 0
                    let windSpeed = wind["speed"] as? Double
                    
                    return HourlyForecast(
                        time: itemDate,
                        temp: temp,
                        emoji: emoji,
                        description: description,
                        humidity: humidity,
                        windSpeed: windSpeed
                    )
                }
                .prefix(24) // Limit to next 24 hours
            
            print("✅ Forecast loaded: \(forecasts.count) hours")
            return Array(forecasts)
        } catch {
            print("Forecast fetch error: \(error.localizedDescription)")
            return nil
        }
    }
}

