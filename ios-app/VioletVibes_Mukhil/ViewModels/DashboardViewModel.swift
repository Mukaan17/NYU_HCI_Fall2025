//
//  DashboardViewModel.swift
//  VioletVibes
//

import Foundation
import SwiftUI
import Observation

@Observable
final class DashboardViewModel {
    var weather: Weather?
    var recommendations: [Recommendation] = []
    
    private let weatherService = WeatherService.shared
    private let apiService = APIService.shared
    
    func loadWeather(latitude: Double, longitude: Double) async {
        print("🌤️ Loading weather for location: \(latitude), \(longitude)")
        do {
            if let weather = await weatherService.getWeather(lat: latitude, lon: longitude) {
                await MainActor.run {
                    self.weather = weather
                    print("✅ Weather loaded successfully: \(weather.temp)°F \(weather.emoji)")
                }
            } else {
                print("⚠️ Weather service returned nil - check API key and network connection")
            }
        } catch {
            print("❌ Weather loading error: \(error.localizedDescription)")
        }
    }
    
    
    // Sample recommendations for dashboard
    func loadSampleRecommendations() {
        recommendations = [
            Recommendation(
                id: 1,
                title: "Fulton Jazz Lounge",
                description: "Live jazz tonight at 8 PM",
                walkTime: "7 min walk",
                popularity: "High",
                image: nil  // Remove placeholder to avoid network errors
            ),
            Recommendation(
                id: 2,
                title: "Brooklyn Rooftop",
                description: "Great vibes & skyline views",
                walkTime: "12 min walk",
                popularity: "Medium",
                image: nil  // Remove placeholder to avoid network errors
            ),
            Recommendation(
                id: 3,
                title: "Butler Café",
                description: "Great for study breaks",
                walkTime: "3 min walk",
                popularity: "Low",
                image: nil  // Remove placeholder to avoid network errors
            )
        ]
    }
}

