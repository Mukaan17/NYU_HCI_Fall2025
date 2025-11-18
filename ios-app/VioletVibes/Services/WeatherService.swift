//
//  WeatherService.swift
//  VioletVibes
//

import Foundation

class WeatherService {
    static let shared = WeatherService()
    
    private let apiKey: String?
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    
    private init() {
        // Get API key from environment or Info.plist
        if let key = ProcessInfo.processInfo.environment["OPENWEATHER_KEY"] {
            apiKey = key
        } else if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
                  let config = NSDictionary(contentsOfFile: path),
                  let key = config["OPENWEATHER_KEY"] as? String {
            apiKey = key
        } else {
            apiKey = nil
        }
    }
    
    func getWeather(lat: Double, lon: Double) async -> Weather? {
        guard let apiKey = apiKey else {
            print("OpenWeather API key not found")
            return nil
        }
        
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "imperial")
        ]
        
        guard let url = urlComponents.url else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let weather = try decoder.decode(Weather.self, from: data)
            return weather
        } catch {
            print("Weather fetch error: \(error)")
            return nil
        }
    }
}

