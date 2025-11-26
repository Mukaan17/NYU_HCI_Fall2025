//
//  DashboardView.swift
//  VioletVibes
//

import SwiftUI
import CoreLocation

struct DashboardView: View {
    @Environment(LocationManager.self) private var locationManager
    @State private var viewModel = DashboardViewModel()
    @State private var navigateToCategory: String?
    
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
                                    // Account Settings action
                                }) {
                                    Label("Account Settings", systemImage: "gearshape.fill")
                                }
                                
                                Button(action: {
                                    // About action
                                }) {
                                    Label("About", systemImage: "info.circle")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive, action: {
                                    // Logout action
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
                            if let weather = viewModel.weather {
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
                                GridItem(.flexible(), spacing: Theme.Spacing.`2xl`),
                                GridItem(.flexible(), spacing: Theme.Spacing.`2xl`)
                            ], spacing: Theme.Spacing.`2xl`) {
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
            }
            .navigationDestination(for: String.self) { category in
                QuickResultsView(category: category)
            }
            .navigationBarHidden(true)
        }
        .task {
            // Load sample recommendations first (doesn't require network)
            // This should happen immediately to show content
            await MainActor.run {
                viewModel.loadSampleRecommendations()
            }
            
            // Try to load weather - use user location or fallback to Brooklyn
            if let location = locationManager.location {
                await viewModel.loadWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            } else {
                // Fallback to Brooklyn coordinates (2 MetroTech Center)
                print("Dashboard: No location available, using default Brooklyn location for weather")
                await viewModel.loadWeather(latitude: 40.693393, longitude: -73.98555)
            }
            
        }
        .onChange(of: locationManager.location) { oldValue, newValue in
            // Reload weather when location changes
            if let location = newValue {
                Task {
                    await viewModel.loadWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                }
            }
        }
        .onAppear {
            // Ensure recommendations are loaded even if task fails
            if viewModel.recommendations.isEmpty {
                viewModel.loadSampleRecommendations()
            }
            
            // Try to load weather on appear - use user location or fallback
            if let location = locationManager.location {
                Task {
                    await viewModel.loadWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                }
            } else if viewModel.weather == nil {
                // Only load default if weather hasn't been loaded yet
                Task {
                    await viewModel.loadWeather(latitude: 40.693393, longitude: -73.98555)
                }
            }
        }
    }
}

struct QuickActionCard: View {
    let action: QuickAction
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(value: action.prompt) {
        VStack(spacing: Theme.Spacing.`2xl`) {
            Text(action.icon)
                .font(.system(size: 32))
            
            Text(action.label)
                .themeFont(size: .base, weight: .semiBold)
                .foregroundColor(Theme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1.2, contentMode: .fit)
        .padding(Theme.Spacing.`2xl`)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                    .fill(.ultraThinMaterial)
                
                LinearGradient(
                    colors: [
                        action.color.opacity(0.4),
                        action.color.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(Theme.BorderRadius.md)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                    .stroke(Theme.Colors.border.opacity(0.15), lineWidth: 1)
        )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2)) {
                        isPressed = false
                    }
                }
        )
    }
}


