//
//  DashboardViewModel.swift
//  VioletVibes
//

import Foundation
import SwiftUI

class DashboardViewModel: ObservableObject {
    @Published var weather: Weather?
    @Published var recommendations: [Recommendation] = []
    @Published var showNotification: Bool = false
    
    private let weatherService = WeatherService.shared
    private let apiService = APIService.shared
    
    func loadWeather(latitude: Double, longitude: Double) async {
        if let weather = await weatherService.getWeather(lat: latitude, lon: longitude) {
            await MainActor.run {
                self.weather = weather
            }
        }
    }
    
    func showDemoNotification() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showNotification = true
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
                image: "https://via.placeholder.com/96"
            ),
            Recommendation(
                id: 2,
                title: "Brooklyn Rooftop",
                description: "Great vibes & skyline views",
                walkTime: "12 min walk",
                popularity: "Medium",
                image: "https://via.placeholder.com/96"
            ),
            Recommendation(
                id: 3,
                title: "Butler Café",
                description: "Great for study breaks",
                walkTime: "3 min walk",
                popularity: "Low",
                image: "https://via.placeholder.com/96"
            )
        ]
    }
}

