//
//  DashboardView.swift
//  VioletVibes
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var viewModel = DashboardViewModel()
    @State private var navigateToCategory: String?
    
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
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.`4xl`) {
                        // Header
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Hey there! 👋")
                                .themeFont(size: .`3xl`, weight: .bold)
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            Text("Here's what's happening around you")
                                .themeFont(size: .lg)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, Theme.Spacing.`3xl`)
                        
                        // Badges
                        HStack(spacing: Theme.Spacing.lg) {
                            // Weather Badge
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
                                    NavigationLink(value: action.prompt) {
                                        QuickActionCard(action: action)
                                    }
                                    .buttonStyle(PlainButtonStyle())
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
            }
            .navigationDestination(for: String.self) { category in
                QuickResultsView(category: category)
            }
            .navigationBarHidden(true)
        }
        .task {
            if let location = locationManager.location {
                await viewModel.loadWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            }
            viewModel.loadSampleRecommendations()
            viewModel.showDemoNotification()
        }
        .overlay(
            NotificationView(
                visible: viewModel.showNotification,
                onDismiss: { viewModel.showNotification = false },
                onViewEvent: {
                    viewModel.showNotification = false
                },
                message: "You're free till 8 PM — Live jazz at Fulton St starts soon (7 min walk)."
            )
        )
    }
}

struct QuickActionCard: View {
    let action: QuickAction
    @State private var isPressed = false
    
    var body: some View {
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
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
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

