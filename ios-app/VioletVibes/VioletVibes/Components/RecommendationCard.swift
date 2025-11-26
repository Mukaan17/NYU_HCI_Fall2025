//
//  RecommendationCard.swift
//  VioletVibes
//

import SwiftUI

struct RecommendationCard: View {
    let recommendation: Recommendation
    let onPress: (() -> Void)?
    
    init(recommendation: Recommendation, onPress: (() -> Void)? = nil) {
        self.recommendation = recommendation
        self.onPress = onPress
    }
    
    var body: some View {
        Button(action: {
            onPress?()
        }) {
            HStack(spacing: Theme.Spacing.`2xl`) {
                // Image
                if let imageURL = recommendation.image {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 96, height: 96)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "photo")
                                .foregroundColor(Theme.Colors.textSecondary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 96, height: 96)
                    .cornerRadius(Theme.BorderRadius.md)
                    .clipped()
                }
                
                // Content
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text(recommendation.title)
                        .themeFont(size: .`2xl`, weight: .semiBold)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    if let description = recommendation.description {
                        Text(description)
                            .themeFont(size: .lg)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    
                    // Badges
                    HStack(spacing: Theme.Spacing.`2xl`) {
                        if let walkTime = recommendation.walkTime {
                            Text(walkTime)
                                .themeFont(size: .xs)
                                .foregroundColor(Theme.Colors.textAccent)
                                .padding(.horizontal, Theme.Spacing.lg)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(Theme.Colors.accentPurpleText)
                                .cornerRadius(Theme.BorderRadius.full)
                        }
                        
                        if let popularity = recommendation.popularity {
                            Text(popularity)
                                .themeFont(size: .xs)
                                .foregroundColor(Theme.Colors.textBlue)
                                .padding(.horizontal, Theme.Spacing.lg)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(Theme.Colors.accentBlue)
                                .cornerRadius(Theme.BorderRadius.full)
                        }
                    }
                }
                
                Spacer()
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
                            Theme.Colors.glassBackground,
                            Theme.Colors.glassBackgroundDark
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(Theme.BorderRadius.lg)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.BorderRadius.lg)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(CardButtonStyle())
    }
}

// Custom button style that provides visual feedback without interfering with scrolling
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
