//
//  DashboardViewModel.swift
//  VioletVibes
//

import Foundation
import SwiftUI
import Observation

@Observable
final class DashboardViewModel {
    var recommendations: [Recommendation] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    private let apiService = APIService.shared
    
    // Load recommendations from backend
    func loadRecommendations(jwt: String? = nil, preferences: UserPreferences? = nil, weather: String? = nil, vibe: String? = nil) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Try to get top recommendations from backend
            let topRecs = try await apiService.getTopRecommendations(
                limit: 3,
                jwt: jwt,
                preferences: preferences,
                weather: weather,
                vibe: vibe
            )
            
            await MainActor.run {
                if topRecs.isEmpty {
                    // If API returns empty, use sample data
                    print("⚠️ API returned empty recommendations, using sample data")
                    loadSampleRecommendations()
                } else {
                    // Deduplicate recommendations by title and location
                    var deduplicated: [Recommendation] = []
                    var seenKeys = Set<String>()
                    
                    for rec in topRecs {
                        // Create a unique key from title and location
                        let normalizedTitle = rec.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                        let normalizedLat = rec.lat.map { String(format: "%.4f", $0) } ?? "0"
                        let normalizedLng = rec.lng.map { String(format: "%.4f", $0) } ?? "0"
                        let uniqueKey = "\(normalizedTitle)-\(normalizedLat)-\(normalizedLng)"
                        
                        if seenKeys.contains(uniqueKey) {
                            continue
                        }
                        seenKeys.insert(uniqueKey)
                        
                        // Ensure unique ID for SwiftUI ForEach
                        var uniqueRec = rec
                        if uniqueRec.id == 0 {
                            // Generate a unique ID from the unique key
                            uniqueRec = Recommendation(
                                id: abs(uniqueKey.hashValue) % Int.max,
                                title: rec.title,
                                description: rec.description,
                                distance: rec.distance,
                                walkTime: rec.walkTime,
                                lat: rec.lat,
                                lng: rec.lng,
                                popularity: rec.popularity,
                                image: rec.image
                            )
                        }
                        
                        deduplicated.append(uniqueRec)
                    }
                    
                    recommendations = deduplicated
                    print("✅ Loaded \(deduplicated.count) unique recommendations (from \(topRecs.count) total)")
                }
                isLoading = false
            }
        } catch {
            // Log the error and fallback to sample recommendations
            print("❌ Failed to load recommendations: \(error)")
            if let apiError = error as? APIError {
                print("   Error type: \(apiError)")
            }
            await MainActor.run {
                loadSampleRecommendations()
                isLoading = false
                errorMessage = "Using sample recommendations (API unavailable)"
            }
        }
    }
    
    // Sample recommendations for dashboard (fallback)
    func loadSampleRecommendations() {
        recommendations = [
            Recommendation(
                id: 1,
                title: "Fulton Jazz Lounge",
                description: "Live jazz tonight at 8 PM",
                walkTime: "7 min walk",
                popularity: "High",
                image: nil
            ),
            Recommendation(
                id: 2,
                title: "Brooklyn Rooftop",
                description: "Great vibes & skyline views",
                walkTime: "12 min walk",
                popularity: "Medium",
                image: nil
            ),
            Recommendation(
                id: 3,
                title: "Butler Café",
                description: "Great for study breaks",
                walkTime: "3 min walk",
                popularity: "Low",
                image: nil
            )
        ]
    }
}

