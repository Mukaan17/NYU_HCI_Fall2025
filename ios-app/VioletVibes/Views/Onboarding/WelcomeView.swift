//
//  WelcomeView.swift
//  VioletVibes
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Gradient
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
                
                // Content
                VStack(spacing: Theme.Spacing.`5xl`) {
                    Spacer()
                    
                    // Icon Bubble
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.accentPurple.opacity(0.348))
                            .frame(width: min(geometry.size.width * 0.35, 140), height: min(geometry.size.width * 0.35, 140))
                            .blur(radius: 40)
                        
                        Circle()
                            .fill(Theme.Colors.backgroundCard)
                            .frame(width: min(geometry.size.width * 0.35, 140), height: min(geometry.size.width * 0.35, 140))
                            .overlay(
                                Circle()
                                    .stroke(Theme.Colors.border, lineWidth: 1)
                            )
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: min(geometry.size.width * 0.25, 100)))
                            .foregroundColor(.white)
                    }
                    
                    // Heading
                    Text("Hey There 👋")
                        .themeFont(size: .`3xl`, weight: .bold)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    // Description
                    VStack(spacing: Theme.Spacing.xs) {
                        Text("I'm ")
                            .themeFont(size: .lg)
                            .foregroundColor(Theme.Colors.textSecondary)
                        + Text("Violet")
                            .themeFont(size: .lg, weight: .semiBold)
                            .foregroundColor(Theme.Colors.textAccent)
                        + Text(", your AI concierge for Downtown")
                            .themeFont(size: .lg)
                            .foregroundColor(Theme.Colors.textSecondary)
                        + Text("Brooklyn. Let's find your next vibe.")
                            .themeFont(size: .lg)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
                    
                    // Button
                    PrimaryButton(title: "Let's Go") {
                        onboardingViewModel.markWelcomeSeen()
                    }
                    .padding(.horizontal, Theme.Spacing.`2xl`)
                    .padding(.horizontal, Theme.Spacing.`2xl`)
                    
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.`2xl`)
            }
        }
    }
}

