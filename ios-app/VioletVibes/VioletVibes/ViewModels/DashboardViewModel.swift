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
    
    // Dashboard data properties
    var dashboardData: DashboardAPIResponse? = nil
    var freeTimeSuggestion: FreeTimeSuggestion? = nil
    var nextFreeBlock: FreeTimeBlock? = nil
    var calendarLinked: Bool = false
    var dashboardWeather: Weather? = nil
    
    private let apiService = APIService.shared
    private var currentLoadTask: Task<Void, Never>? = nil
    
    // Load dashboard data from backend
    func loadDashboard(jwt: String) async {
        // Cancel any existing load task to prevent concurrent requests
        await MainActor.run {
            currentLoadTask?.cancel()
        }
        
        // Check for cancellation
        try? Task.checkCancellation()
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let dashboard = try await apiService.getDashboard(jwt: jwt)
            
            // Check for cancellation before processing
            try Task.checkCancellation()
            
            await MainActor.run {
                dashboardData = dashboard
                
                // Extract weather
                dashboardWeather = dashboard.weather
                
                // Extract calendar linked status from backend (source of truth)
                // This ensures local state stays in sync with backend Postgres/Redis
                calendarLinked = dashboard.calendar_linked ?? false
                
                // Extract next free block
                nextFreeBlock = dashboard.next_free
                
                // Extract free-time suggestion
                freeTimeSuggestion = dashboard.free_time_suggestion
                
                // Extract recommendations from all categories
                var allRecommendations: [Recommendation] = []
                
                if let quickRecs = dashboard.quick_recommendations {
                    // Combine recommendations from all categories
                    for (category, recs) in quickRecs {
                        allRecommendations.append(contentsOf: recs)
                    }
                }
                
                // Deduplicate recommendations
                var deduplicated: [Recommendation] = []
                var seenKeys = Set<String>()
                
                for rec in allRecommendations {
                    let normalizedTitle = rec.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    let normalizedLat = rec.lat.map { String(format: "%.4f", $0) } ?? "0"
                    let normalizedLng = rec.lng.map { String(format: "%.4f", $0) } ?? "0"
                    let uniqueKey = "\(normalizedTitle)-\(normalizedLat)-\(normalizedLng)"
                    
                    if seenKeys.contains(uniqueKey) {
                        continue
                    }
                    seenKeys.insert(uniqueKey)
                    
                    var uniqueRec = rec
                    if uniqueRec.id == 0 {
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
                
                // Use top 3 recommendations for main display
                recommendations = Array(deduplicated.prefix(3))
                
                isLoading = false
                print("✅ Loaded dashboard data: \(deduplicated.count) total recommendations")
            }
        } catch {
            print("❌ Failed to load dashboard: \(error)")
            await MainActor.run {
                isLoading = false
                errorMessage = "Dashboard unavailable"
            }
        }
    }
    
    // Load recommendations from backend (with fallback chain)
    func loadRecommendations(jwt: String? = nil, preferences: UserPreferences? = nil, weather: String? = nil, vibe: String? = nil) async {
        // Check for cancellation
        try? Task.checkCancellation()
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Try dashboard first if JWT is available
        if let jwt = jwt {
            do {
                await loadDashboard(jwt: jwt)
                // Check for cancellation
                try Task.checkCancellation()
                // If dashboard loaded successfully, we're done
                if !recommendations.isEmpty {
                    await MainActor.run {
                        isLoading = false
                    }
                    return
                }
            } catch is CancellationError {
                // Task was cancelled, exit gracefully
                await MainActor.run {
                    isLoading = false
                }
                return
            } catch {
                print("⚠️ Dashboard load failed, falling back to top recommendations: \(error)")
            }
        }
        
        // Fallback to top recommendations
        do {
            // Check for cancellation
            try Task.checkCancellation()
            
            // Try to get top recommendations from backend
            let topRecs = try await apiService.getTopRecommendations(
                limit: 3,
                jwt: jwt,
                preferences: preferences,
                weather: weather,
                vibe: vibe
            )
            
            // Check for cancellation before processing
            try Task.checkCancellation()
            
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
        } catch is CancellationError {
            // Task was cancelled, exit gracefully
            await MainActor.run {
                isLoading = false
            }
            return
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

