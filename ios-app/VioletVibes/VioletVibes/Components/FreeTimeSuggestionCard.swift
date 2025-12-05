//
//  FreeTimeSuggestionCard.swift
//  VioletVibes
//

import SwiftUI

struct FreeTimeSuggestionCard: View {
    let suggestion: FreeTimeSuggestion
    let nextFree: FreeTimeBlock?
    let onViewDetails: (() -> Void)?
    let onGetDirections: (() -> Void)?
    
    init(
        suggestion: FreeTimeSuggestion,
        nextFree: FreeTimeBlock? = nil,
        onViewDetails: (() -> Void)? = nil,
        onGetDirections: (() -> Void)? = nil
    ) {
        self.suggestion = suggestion
        self.nextFree = nextFree
        self.onViewDetails = onViewDetails
        self.onGetDirections = onGetDirections
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.`2xl`) {
            // Message
            Text(suggestion.message)
                .themeFont(size: .lg, weight: .medium)
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.leading)
            
            // Suggestion content
            HStack(spacing: Theme.Spacing.`2xl`) {
                // Image
                if let photoURL = suggestion.suggestion.photo_url {
                    AsyncImage(url: URL(string: photoURL)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 96, height: 96)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: suggestion.type == "event" ? "calendar" : "mappin.circle.fill")
                                .foregroundColor(Theme.Colors.textSecondary)
                                .font(.system(size: 48))
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 96, height: 96)
                    .cornerRadius(Theme.BorderRadius.md)
                    .clipped()
                } else {
                    // Placeholder icon
                    Image(systemName: suggestion.type == "event" ? "calendar" : "mappin.circle.fill")
                        .foregroundColor(Theme.Colors.textSecondary)
                        .font(.system(size: 48))
                        .frame(width: 96, height: 96)
                        .background(Theme.Colors.glassBackground)
                        .cornerRadius(Theme.BorderRadius.md)
                }
                
                // Content
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    if let name = suggestion.suggestion.name {
                        Text(name)
                            .themeFont(size: .`2xl`, weight: .semiBold)
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                    
                    if let location = suggestion.suggestion.location {
                        Text(location)
                            .themeFont(size: .base)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    
                    if let description = suggestion.suggestion.description {
                        Text(description)
                            .themeFont(size: .sm)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .lineLimit(2)
                    }
                    
                    // Type badge
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: suggestion.type == "event" ? "calendar.badge.clock" : "location.fill")
                            .font(.system(size: 12))
                        Text(suggestion.type == "event" ? "Event" : "Place")
                            .themeFont(size: .xs, weight: .medium)
                    }
                    .foregroundColor(Theme.Colors.textAccent)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(Theme.Colors.accentPurpleText)
                    .cornerRadius(Theme.BorderRadius.full)
                }
                
                Spacer()
            }
            
            // Action buttons
            HStack(spacing: Theme.Spacing.lg) {
                if let onViewDetails = onViewDetails {
                    Button(action: onViewDetails) {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("View Details")
                        }
                        .themeFont(size: .base, weight: .semiBold)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Theme.Colors.glassBackground)
                        .cornerRadius(Theme.BorderRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                    }
                }
                
                if let mapsLink = suggestion.suggestion.maps_link, !mapsLink.isEmpty, let onGetDirections = onGetDirections {
                    Button(action: onGetDirections) {
                        HStack {
                            Image(systemName: "arrow.triangle.turn.up.right.diamond")
                            Text("Get Directions")
                        }
                        .themeFont(size: .base, weight: .semiBold)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Theme.Colors.accentBlue)
                        .cornerRadius(Theme.BorderRadius.md)
                    }
                }
            }
        }
        .padding(Theme.Spacing.`2xl`)
        .background(
            ZStack {
                // Glass effect
                RoundedRectangle(cornerRadius: Theme.BorderRadius.lg)
                    .fill(.ultraThinMaterial)
                
                // Gradient overlay
                LinearGradient(
                    colors: [
                        Theme.Colors.accentPurpleMedium.opacity(0.2),
                        Theme.Colors.accentBlue.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(Theme.BorderRadius.lg)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.BorderRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [
                            Theme.Colors.accentPurpleMedium.opacity(0.5),
                            Theme.Colors.accentBlue.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
}
