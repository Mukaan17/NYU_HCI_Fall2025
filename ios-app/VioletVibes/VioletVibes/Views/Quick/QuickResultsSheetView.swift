//
//  QuickResultsSheetView.swift
//  VioletVibes
//

import SwiftUI

struct QuickResultsSheetView: View {
    let category: String
    @Environment(PlaceViewModel.self) private var placeViewModel
    @Environment(TabCoordinator.self) private var tabCoordinator    // 👈 add this
    @Environment(\.dismiss) private var dismiss
    
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
        NavigationStack {
            ZStack {
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
                
                GeometryReader { geometry in
                    Circle()
                        .fill(Theme.Colors.gradientStart.opacity(0.15))
                        .frame(width: 300, height: 300)
                        .offset(x: -50, y: -100)
                        .blur(radius: 60)
                    
                    Circle()
                        .fill(Theme.Colors.gradientStart.opacity(0.12))
                        .frame(width: 250, height: 250)
                        .offset(x: geometry.size.width - 200, y: geometry.size.height - 200)
                        .blur(radius: 50)
                }
                .allowsHitTesting(false)
                
                if loading {
                    ProgressView()
                        .tint(Theme.Colors.gradientStart)
                } else if places.isEmpty {
                    VStack(spacing: Theme.Spacing.`2xl`) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        Text("No places found")
                            .themeFont(size: .lg)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                } else {
                    List {
                        ForEach(places) { place in
                            QuickResultRow(place: place) {
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
                                tabCoordinator.selectedTab = .map      // 👈 go to map
                                dismiss()
                            }
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                    .fill(.regularMaterial)
                                    .padding(.vertical, Theme.Spacing.xs)
                            )
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(readableTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.gradientStart)
                }
            }
            .tint(Theme.Colors.gradientStart)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground {
            ZStack {
                RoundedRectangle(cornerRadius: 0)
                    .fill(.regularMaterial)
                
                LinearGradient(
                    colors: [
                        Theme.Colors.gradientStart.opacity(0.1),
                        Theme.Colors.gradientEnd.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .task(id: category) {
            await MainActor.run {
                places = []
            }
            await loadPlaces()
        }
    }
    
    private func loadPlaces() async {
        loading = true
        do {
            let response = try await apiService.getQuickRecommendations(category: category, limit: 10)
            
            await MainActor.run {
                places = response.places.uniqued()
                print("✅ Loaded \(places.count) unique places")
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

// MARK: - Quick Result Row View

struct QuickResultRow: View {
    let place: Recommendation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.`2xl`) {
                // Image or placeholder
                if let imageURL = place.image, !imageURL.isEmpty {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                            .fill(Theme.Colors.gradientStart.opacity(0.2))
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundColor(Theme.Colors.gradientStart)
                            }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.BorderRadius.md))
                } else {
                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                        .fill(Theme.Colors.gradientStart.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(Theme.Colors.gradientStart)
                        }
                }
                
                // Content
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(place.title)
                        .themeFont(size: .lg, weight: .semiBold)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    if let description = place.description, !description.isEmpty {
                        Text(description)
                            .themeFont(size: .sm)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    HStack(spacing: Theme.Spacing.lg) {
                        if let walkTime = place.walkTime {
                            Label("\(walkTime)", systemImage: "figure.walk")
                                .themeFont(size: .xs)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        
                        if let distance = place.distance {
                            Label("\(distance)", systemImage: "location")
                                .themeFont(size: .xs)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(Theme.Spacing.`2xl`)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                        .fill(.regularMaterial)
                    
                    LinearGradient(
                        colors: [
                            Theme.Colors.gradientStart.opacity(0.1),
                            Theme.Colors.gradientEnd.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(Theme.BorderRadius.md)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Array Unique Extension

extension Array where Element: Identifiable {
    func uniqued() -> [Element] {
        var seen = Set<Element.ID>()
        return self.filter { seen.insert($0.id).inserted }
    }
}
