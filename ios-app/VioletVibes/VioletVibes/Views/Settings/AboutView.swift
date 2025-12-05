//
//  AboutView.swift
//  VioletVibes
//

import SwiftUI
import UIKit

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tapCount = 0
    @State private var showConfetti = false
    @State private var lastTapTime: Date?
    @State private var logoPosition: CGPoint = .zero
    
    var body: some View {
        NavigationStack {
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
                
                // Blur Shapes
                GeometryReader { geometry in
                    Circle()
                        .fill(Theme.Colors.accentPurpleMedium.opacity(0.15))
                        .frame(width: geometry.size.width * 0.75, height: geometry.size.width * 0.75)
                        .offset(x: -geometry.size.width * 0.2, y: -100)
                        .blur(radius: 60)
                    
                    Circle()
                        .fill(Theme.Colors.accentBlue.opacity(0.12))
                        .frame(width: geometry.size.width * 0.6, height: geometry.size.width * 0.6)
                        .offset(x: geometry.size.width * 0.3, y: geometry.size.height * 0.5)
                        .blur(radius: 50)
                }
                .allowsHitTesting(false)
                
                ZStack {
                    // Confetti overlay
                    if showConfetti {
                        ConfettiView(isActive: $showConfetti, emitterPosition: logoPosition)
                            .allowsHitTesting(false)
                            .ignoresSafeArea()
                    }
                    
                    ScrollView {
                        VStack(spacing: Theme.Spacing.`4xl`) {
                            // App Icon/Logo
                            Group {
                                if let appIcon = UIImage(named: "AppIcon") ?? getAppIcon() {
                                    Image(uiImage: appIcon)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 120, height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 26))
                                        .shadow(color: Theme.Colors.gradientStart.opacity(0.3), radius: 20, x: 0, y: 10)
                                } else {
                                    // Fallback if app icon not found
                                    ZStack {
                                        Circle()
                                            .fill(Theme.Colors.accentPurple.opacity(0.2))
                                            .frame(width: 120, height: 120)
                                            .blur(radius: 40)
                                        
                                        Circle()
                                            .fill(Theme.Colors.backgroundCard)
                                            .frame(width: 120, height: 120)
                                            .overlay(
                                                Circle()
                                                    .stroke(Theme.Colors.border, lineWidth: 1)
                                            )
                                        
                                        Image(systemName: "app.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(Theme.Colors.gradientStart)
                                    }
                                }
                            }
                            .padding(.top, Theme.Spacing.`4xl`)
                            .overlay(
                                GeometryReader { geometry in
                                    Color.clear
                                        .onAppear {
                                            // Calculate logo position in screen coordinates
                                            logoPosition = CGPoint(
                                                x: geometry.frame(in: .global).midX,
                                                y: geometry.frame(in: .global).midY
                                            )
                                        }
                                        .onChange(of: geometry.frame(in: .global)) { oldValue, newValue in
                                            logoPosition = CGPoint(
                                                x: newValue.midX,
                                                y: newValue.midY
                                            )
                                        }
                                }
                            )
                            .onTapGesture {
                                handleLogoTap()
                            }
                        
                        // App Name
                        Text("Violet Vibes")
                            .themeFont(size: .`3xl`, weight: .bold)
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        // Copyright
                        VStack(spacing: Theme.Spacing.lg) {
                            Text("© 2025 Violet Vibes")
                                .themeFont(size: .base)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            Divider()
                                .background(Theme.Colors.whiteOverlay)
                                .padding(.horizontal, Theme.Spacing.`4xl`)
                            
                            // Developers Section
                            VStack(spacing: Theme.Spacing.`2xl`) {
                                Text("Developed by")
                                    .themeFont(size: .sm)
                                    .foregroundColor(Theme.Colors.textSecondary)
                                    .textCase(.uppercase)
                                
                                VStack(spacing: Theme.Spacing.lg) {
                                    Text("Christine Wagner")
                                        .themeFont(size: .lg, weight: .semiBold)
                                        .foregroundColor(Theme.Colors.textPrimary)
                                    
                                    Text("Mukhil Sundararaj Gowthaman")
                                        .themeFont(size: .lg, weight: .semiBold)
                                        .foregroundColor(Theme.Colors.textPrimary)
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.`2xl`)
                        }
                        .padding(.bottom, Theme.Spacing.`4xl`)
                    }
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.gradientStart)
                }
            }
        }
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
    
    private func handleLogoTap() {
        let now = Date()
        
        // Reset counter if more than 2 seconds have passed since last tap
        if let lastTap = lastTapTime, now.timeIntervalSince(lastTap) > 2.0 {
            tapCount = 0
        }
        
        tapCount += 1
        lastTapTime = now
        
        // Haptic feedback for each tap
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Trigger confetti on 8th tap
        if tapCount >= 8 {
            // Success haptic
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            
            // Show confetti
            showConfetti = true
            
            // Reset counter
            tapCount = 0
            lastTapTime = nil
        }
    }
}

