//
//  WelcomeView.swift
//  VioletVibes
//
//  Swift 6.2 compliant - optimized for type-checking performance

import SwiftUI
import UIKit

struct WelcomeView: View {
    @Environment(OnboardingViewModel.self) private var onboardingViewModel
    @Environment(AppStateManager.self) private var appStateManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundGradient
                blurShapes(geometry: geometry)
                contentView(geometry: geometry)
            }
        }
    }
    
    // MARK: - View Components (Swift 6.2: Breaking complex expressions into sub-expressions)
    
    private var backgroundGradient: some View {
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
    }
                
    @ViewBuilder
    private func blurShapes(geometry: GeometryProxy) -> some View {
                Circle()
                    .fill(Theme.Colors.accentPurpleMedium.opacity(0.881))
                    .frame(width: geometry.size.width * 0.75, height: geometry.size.width * 0.75)
                    .offset(x: -geometry.size.width * 0.2, y: 0)
                    .blur(radius: 80)
                
                Circle()
                    .fill(Theme.Colors.accentBlue.opacity(0.619))
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .offset(x: geometry.size.width * 0.22, y: geometry.size.height * 0.3)
                    .blur(radius: 60)
    }
                
    @ViewBuilder
    private func contentView(geometry: GeometryProxy) -> some View {
                VStack(spacing: Theme.Spacing.`5xl`) {
                    Spacer()
            iconBubble(geometry: geometry)
            heading
            description
            actionButton
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.`2xl`)
    }
    
    @ViewBuilder
    private func iconBubble(geometry: GeometryProxy) -> some View {
        if let appIcon = UIImage(named: "AppIcon") ?? getAppIcon() {
            Image(uiImage: appIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize(geometry), height: iconSize(geometry))
                .clipShape(RoundedRectangle(cornerRadius: iconSize(geometry) * 0.2))
                .shadow(color: Theme.Colors.gradientStart.opacity(0.3), radius: 20, x: 0, y: 10)
        } else {
            // Fallback if app icon not found
            ZStack {
                Circle()
                    .fill(Theme.Colors.accentPurple.opacity(0.348))
                    .frame(width: iconSize(geometry), height: iconSize(geometry))
                    .blur(radius: 40)
                
                Circle()
                    .fill(Theme.Colors.backgroundCard)
                    .frame(width: iconSize(geometry), height: iconSize(geometry))
                    .overlay(
                        Circle()
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                
                Image(systemName: "app.fill")
                    .font(.system(size: iconImageSize(geometry)))
                    .foregroundColor(.white)
            }
        }
    }
                    
    private var heading: some View {
                    Text("Hey There 👋")
                        .themeFont(size: .`3xl`, weight: .bold)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
    }
                    
    private var description: some View {
                    VStack(spacing: Theme.Spacing.xs) {
            HStack(spacing: 0) {
                        Text("I'm ")
                            .themeFont(size: .lg)
                            .foregroundColor(Theme.Colors.textSecondary)
                Text("Violet")
                            .themeFont(size: .lg, weight: .semiBold)
                            .foregroundColor(Theme.Colors.textAccent)
                Text(", your AI concierge for Downtown")
                            .themeFont(size: .lg)
                            .foregroundColor(Theme.Colors.textSecondary)
            }
            Text("Brooklyn. Let's find your next vibe.")
                            .themeFont(size: .lg)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
    }
                    
    private var actionButton: some View {
                    PrimaryButton(title: "Let's Go") {
                        Task { @MainActor in
                            await appStateManager.handleWelcomeCompleted(onboardingViewModel: onboardingViewModel)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.`2xl`)
    }
    
    // MARK: - Helper Methods
    
    private func iconSize(_ geometry: GeometryProxy) -> CGFloat {
        min(geometry.size.width * 0.35, 140)
                }
    
    private func iconImageSize(_ geometry: GeometryProxy) -> CGFloat {
        min(geometry.size.width * 0.25, 100)
    }
    
    // Helper function to get app icon programmatically
    private func getAppIcon() -> UIImage? {
        // Try to get app icon from bundle
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String] {
            // Try the largest icon first (usually the last one)
            for iconName in iconFiles.reversed() {
                if let image = UIImage(named: iconName) {
                    return image
                }
            }
        }
        
        // Fallback: try common app icon asset names
        let commonNames = ["AppIcon", "AppIconImage", "Icon", "App"]
        for name in commonNames {
            if let image = UIImage(named: name) {
                return image
            }
        }
        
        return nil
    }
}

