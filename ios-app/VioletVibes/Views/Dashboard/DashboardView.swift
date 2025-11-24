//
//  DashboardView.swift
//  VioletVibes
//

import SwiftUI
import CoreLocation

struct DashboardView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(WeatherManager.self) private var weatherManager
    @Environment(OnboardingViewModel.self) private var onboardingViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = DashboardViewModel()
    @State private var navigateToCategory: String?
    @State private var showLogoutAlert = false
    @State private var showAboutView = false
    @State private var showAccountSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background - use explicit colors for debugging
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
                        .fill(Theme.Colors.accentPurpleMedium.opacity(0.85))
                        .frame(width: geometry.size.width * 0.75, height: geometry.size.width * 0.75)
                        .offset(x: -geometry.size.width * 0.2, y: geometry.size.height * 0.1)
                        .blur(radius: 80)
                    
                    Circle()
                        .fill(Theme.Colors.accentBlue.opacity(0.6))
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .offset(x: geometry.size.width * 0.22, y: geometry.size.height * 0.35)
                        .blur(radius: 60)
                }
                .allowsHitTesting(false)
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.`4xl`) {
                        // Header with Profile Button
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("Hey there! 👋")
                                    .themeFont(size: .`3xl`, weight: .bold)
                                    .foregroundColor(Theme.Colors.textPrimary)
                                
                                Text("Here's what's happening around you")
                                    .themeFont(size: .lg)
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            // Profile Button - Scrolls with content
                            Menu {
                                Button(action: {
                                    showAccountSettings = true
                                }) {
                                    Label("Account Settings", systemImage: "gearshape.fill")
                                }
                                
                                Button(action: {
                                    showAboutView = true
                                }) {
                                    Label("About", systemImage: "info.circle")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive, action: {
                                    showLogoutAlert = true
                                }) {
                                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                                }
                            } label: {
                                Image(systemName: "person.crop.circle")
                                    .font(.system(size: 32))
                                    .foregroundColor(Theme.Colors.textPrimary)
                                    .frame(width: 48, height: 48)
                                    .background(
                                        Circle()
                                            .stroke(Theme.Colors.border.opacity(0.2), lineWidth: 2)
                                    )
                            }
                        }
                        .padding(.top, Theme.Spacing.`3xl`)
                        
                        // Badges - Centered horizontally
                        HStack(spacing: Theme.Spacing.lg) {
                            // Weather Badge - Always show, with fallback if weather not loaded
                            if let weather = weatherManager.weather {
                                Text("\(weather.emoji) \(weather.temp)°F")
                                    .themeFont(size: .base, weight: .semiBold)
                                    .foregroundColor(Theme.Colors.textBlue)
                                    .padding(.horizontal, Theme.Spacing.xl)
                                    .padding(.vertical, Theme.Spacing.sm)
                                    .background(Theme.Colors.accentBlue)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                            .stroke(Theme.Colors.accentBlueMedium, lineWidth: 1)
                                    )
                                    .cornerRadius(Theme.BorderRadius.md)
                            } else {
                                // Show loading/placeholder while weather is being fetched
                                HStack(spacing: Theme.Spacing.xs) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(Theme.Colors.textBlue)
                                    Text("Loading...")
                                        .themeFont(size: .base, weight: .semiBold)
                                        .foregroundColor(Theme.Colors.textBlue)
                                }
                                .padding(.horizontal, Theme.Spacing.xl)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(Theme.Colors.accentBlue)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                        .stroke(Theme.Colors.accentBlueMedium, lineWidth: 1)
                                )
                                .cornerRadius(Theme.BorderRadius.md)
                            }
                            
                            // Schedule Badge
                            Text("Free until 6:30 PM")
                                .themeFont(size: .base, weight: .semiBold)
                                .foregroundColor(Theme.Colors.textPrimary)
                                .padding(.horizontal, Theme.Spacing.xl)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(Theme.Colors.glassBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                        .stroke(Theme.Colors.border, lineWidth: 1)
                                )
                                .cornerRadius(Theme.BorderRadius.md)
                            
                            // Mood Badge
                            Text("Chill ✨")
                                .themeFont(size: .base, weight: .semiBold)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .padding(.horizontal, Theme.Spacing.xl)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(Theme.Colors.whiteOverlay)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                        .stroke(Theme.Colors.border, lineWidth: 1)
                                )
                                .cornerRadius(Theme.BorderRadius.md)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, Theme.Spacing.`4xl`)
                        
                        // Quick Actions
                        VStack(alignment: .leading, spacing: Theme.Spacing.`2xl`) {
                            Text("Quick Actions")
                                .themeFont(size: .`2xl`, weight: .bold)
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: Theme.Spacing.md),
                                GridItem(.flexible(), spacing: Theme.Spacing.md)
                            ], spacing: Theme.Spacing.xl) {
                                ForEach(QuickAction.allActions) { action in
                                    QuickActionCard(action: action)
                                }
                            }
                        }
                        
                        // Recommendations
                        VStack(alignment: .leading, spacing: Theme.Spacing.`2xl`) {
                            Text("Top Recommendations")
                                .themeFont(size: .`2xl`, weight: .bold)
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            ForEach(viewModel.recommendations) { recommendation in
                                RecommendationCard(recommendation: recommendation)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.`2xl`)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .scrollBounceBehavior(.basedOnSize)
            }
            .navigationDestination(for: String.self) { category in
                QuickResultsView(category: category)
            }
            .navigationBarHidden(true)
        }
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                onboardingViewModel.resetOnboarding()
            }
        } message: {
            Text("Are you sure you want to log out? You'll need to go through onboarding again.")
        }
        .sheet(isPresented: $showAboutView) {
            AboutView()
        }
        .sheet(isPresented: $showAccountSettings) {
            AccountSettingsView()
        }
        .refreshable {
            // Pull to refresh - reload weather
            await weatherManager.loadWeather(locationManager: locationManager)
        }
        .task {
            // Load sample recommendations first (doesn't require network)
            // This should happen immediately to show content
            await MainActor.run {
                viewModel.loadSampleRecommendations()
            }
            
            // Load weather on task start (app launch/restart)
            await weatherManager.loadWeather(locationManager: locationManager)
        }
        .onChange(of: locationManager.location) { oldValue, newValue in
            // Reload weather when location changes
            if newValue != nil {
                Task {
                    await weatherManager.loadWeather(locationManager: locationManager)
                }
            }
        }
        .onAppear {
            // Ensure recommendations are loaded even if task fails
            if viewModel.recommendations.isEmpty {
                viewModel.loadSampleRecommendations()
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Reload weather when app comes to foreground
            if newPhase == .active && oldPhase != .active {
                print("🔄 Dashboard: App became active - reloading weather")
                locationManager.restartLocationUpdates()
                Task {
                    // Wait a bit for location to update, then load weather
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    await weatherManager.loadWeather(locationManager: locationManager)
                }
            }
        }
    }
}

struct QuickActionCard: View {
    let action: QuickAction
    
    var body: some View {
        NavigationLink(value: action.prompt) {
            VStack(spacing: Theme.Spacing.xs) {
                Text(action.icon)
                    .font(.system(size: 56))
                
                Text(action.label)
                    .themeFont(size: .base, weight: .semiBold)
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1.0, contentMode: .fill)
            .padding(Theme.Spacing.`4xl`)
            .background {
                ZStack {
                    // Native liquid glass material - using regularMaterial for more pronounced blur
                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                        .fill(.regularMaterial)
                    
                    // Subtle color tint gradient
                    LinearGradient(
                        colors: [
                            action.color.opacity(0.3),
                            action.color.opacity(0.15),
                            action.color.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(Theme.BorderRadius.md)
                    
                    // Inner glow effect
                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                        .fill(
                            LinearGradient(
                                colors: [
                                    action.color.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                }
            }
            .overlay {
                // Glass border with subtle highlight
                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .shadow(color: action.color.opacity(0.2), radius: 8, x: 0, y: 4)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


