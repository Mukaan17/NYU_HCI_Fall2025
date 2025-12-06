//
//  QuickResultsSheetView.swift
//  VioletVibes
//

import SwiftUI

struct QuickResultsSheetView: View {
    let category: String
    @Environment(PlaceViewModel.self) private var placeViewModel
    @Environment(TabCoordinator.self) private var tabCoordinator
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
                // Background with liquid glass
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
                
                // Blur Shapes
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
                                tabCoordinator.selectedTab = .map
                                dismiss()
                            }
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                    .fill(.ultraThinMaterial)
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
            // Liquid glass background for sheet
            ZStack {
                RoundedRectangle(cornerRadius: 0)
                    .fill(.ultraThinMaterial)
                
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
            // Reset places before loading to prevent accumulation
            await MainActor.run {
                places = []
            }
            await loadPlaces()
        }
    }
    
    private func loadPlaces() async {
        loading = true
        do {
            // Map "chill_cafes" to "cozy_cafes" for backend compatibility
            let apiCategory = category == "chill_cafes" ? "cozy_cafes" : category
            let response = try await apiService.getQuickRecommendations(category: apiCategory, limit: 10)
            await MainActor.run {
                // Improved deduplication using multiple strategies
                var deduplicatedPlaces: [Recommendation] = []
                var seenIds = Set<Int>()
                var seenKeys = Set<String>()
                
                for place in response.places {
                    // Strategy 1: Deduplicate by ID (if ID is not 0)
                    if place.id != 0 {
                        if seenIds.contains(place.id) {
                            continue
                        }
                        seenIds.insert(place.id)
                    }
                    
                    // Strategy 2: Create a comprehensive unique key from title and location
                    let normalizedTitle = place.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Round coordinates to 4 decimal places (~11 meters precision) to catch nearby duplicates
                    let normalizedLat = place.lat.map { String(format: "%.4f", $0) } ?? "0"
                    let normalizedLng = place.lng.map { String(format: "%.4f", $0) } ?? "0"
                    
                    // Use title + location as primary unique key
                    let uniqueKey = "\(normalizedTitle)-\(normalizedLat)-\(normalizedLng)"
                    
                    if seenKeys.contains(uniqueKey) {
                        continue
                    }
                    seenKeys.insert(uniqueKey)
                    
                    // Ensure unique ID for SwiftUI ForEach
                    var uniquePlace = place
                    if uniquePlace.id == 0 {
                        // Generate a unique ID from the unique key
                        uniquePlace = Recommendation(
                            id: abs(uniqueKey.hashValue) % Int.max,
                            title: place.title,
                            description: place.description,
                            distance: place.distance,
                            walkTime: place.walkTime,
                            lat: place.lat,
                            lng: place.lng,
                            popularity: place.popularity,
                            image: place.image
                        )
                    }
                    
                    deduplicatedPlaces.append(uniquePlace)
                }
                
                places = deduplicatedPlaces
                
                print("✅ Loaded \(places.count) unique places (from \(response.places.count) total)")
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

// MARK: - Quick Result Row
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
                        Text(description.strippingHTML)
                            .themeFont(size: .sm)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    HStack(spacing: Theme.Spacing.lg) {
                        if let walkTime = place.walkTime {
                            Label("\(walkTime) min", systemImage: "figure.walk")
                                .themeFont(size: .xs)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        
                        if let distance = place.distance {
                            Label(String(format: "%.1f mi", distance), systemImage: "location")
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
                        .fill(.ultraThinMaterial)
                    
                    LinearGradient(
                        colors: [
                            Theme.Colors.gradientStart.opacity(0.05),
                            Theme.Colors.gradientEnd.opacity(0.02)
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

// MARK: - String Identifiable Extension
extension String: Identifiable {
    public var id: String { self }
}

