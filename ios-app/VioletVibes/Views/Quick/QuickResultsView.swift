//
//  QuickResultsView.swift
//  VioletVibes
//

import SwiftUI

struct QuickResultsView: View {
    let category: String
    @EnvironmentObject var placeViewModel: PlaceViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var places: [Recommendation] = []
    @State private var loading: Bool = true
    
    private let apiService = APIService.shared
    
    private var readableTitle: String {
        switch category {
        case "quick_bites": return "Quick Bites"
        case "chill_cafes": return "Chill Cafes"
        case "events": return "Events Nearby"
        case "explore": return "Explore"
        default: return "Discover"
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Theme.Colors.background,
                    Theme.Colors.backgroundSecondary,
                    Theme.Colors.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Back Button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(12)
                    }
                    .padding(.leading, Theme.Spacing.`2xl`)
                    .padding(.top, 50)
                    
                    Spacer()
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.`3xl`) {
                        Text(readableTitle)
                            .themeFont(size: .`3xl`, weight: .bold)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .padding(.top, 60)
                            .padding(.horizontal, Theme.Spacing.`2xl`)
                        
                        if loading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        } else if places.isEmpty {
                            Text("No places found")
                                .themeFont(size: .lg)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        } else {
                            ForEach(places) { place in
                                RecommendationCard(recommendation: place) {
                                    let selectedPlace = SelectedPlace(
                                        name: place.title,
                                        latitude: place.lat ?? 40.693393,
                                        longitude: place.lng ?? -73.98555,
                                        walkTime: place.walkTime,
                                        distance: place.distance,
                                        address: place.description,
                                        image: place.image
                                    )
                                    placeViewModel.setSelectedPlace(selectedPlace)
                                    dismiss()
                                }
                                .padding(.horizontal, Theme.Spacing.`2xl`)
                            }
                        }
                    }
                    .padding(.bottom, 140)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadPlaces()
        }
    }
    
    private func loadPlaces() async {
        loading = true
        do {
            let response = try await apiService.getQuickRecommendations(category: category, limit: 10)
            await MainActor.run {
                places = response.places
                loading = false
            }
        } catch {
            print("Quick recs error: \(error)")
            await MainActor.run {
                places = []
                loading = false
            }
        }
    }
}

