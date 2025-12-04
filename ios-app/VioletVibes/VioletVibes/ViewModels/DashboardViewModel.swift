//
//  DashboardViewModel.swift
//  VioletVibes
//

import Foundation
import SwiftUI
import Observation

@Observable
final class DashboardViewModel {

    // MARK: - State
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var recommendations: [Recommendation] = []

    private let api = APIService.shared

    // MARK: - Load Top Recs (JWT + Preferences + Weather)
    @MainActor
    func loadTopRecommendations(
        jwt: String?,
        preferences: UserPreferences?,
        weather: String? = nil,
        limit: Int = 3
    ) async {

        isLoading = true
        errorMessage = nil

        do {
            let results = try await api.getTopRecommendations(
                limit: limit,
                jwt: jwt,
                preferences: preferences,
                weather: weather
            )

            recommendations = results

            if results.isEmpty {
                errorMessage = "No recommendations found."
            }

        } catch {
            print("❌ Top Recommendations Error:", error)
            errorMessage = error.localizedDescription
            recommendations = []
        }

        isLoading = false
    }
}
