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
    @Environment(PlaceViewModel.self) private var placeViewModel
    @Environment(TabCoordinator.self) private var tabCoordinator
    @Environment(UserSession.self) private var session

    @Environment(\.scenePhase) private var scenePhase

    @State private var viewModel = DashboardViewModel()
    @State private var showLogoutAlert = false
    @State private var showAboutView = false
    @State private var showAccountSettings = false
    @State private var selectedQuickAction: String?

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer
                ScrollView {
                    scrollContent
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedQuickAction) { category in
                QuickResultsSheetView(category: category)
            }
        }
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) {
                onboardingViewModel.resetOnboarding()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .sheet(isPresented: $showAboutView) {
            AboutView()
        }
        .sheet(isPresented: $showAccountSettings) {
            AccountSettingsView()
        }

        // Pull-to-refresh → reload EVERYTHING
        .refreshable {
            await loadDashboardData()
        }

        // Initial load
        .task {
            await loadDashboardData()
        }

        // JWT changed → reload EVERYTHING
        .onChange(of: session.jwt) { _, _ in
            Task {
                print("🔑 JWT changed → reload dashboard data")
                await loadDashboardData()
            }
        }

        // App became active → reload EVERYTHING
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await loadDashboardData()
                }
            }
        }
    }
}

//
// MARK: - UI Pieces
//

private extension DashboardView {

    var backgroundLayer: some View {
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
        .overlay(blurShapes)
    }

    var blurShapes: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(Theme.Colors.accentPurpleMedium.opacity(0.85))
                    .frame(width: geo.size.width * 0.75)
                    .offset(x: -geo.size.width * 0.2, y: geo.size.height * 0.1)
                    .blur(radius: 80)

                Circle()
                    .fill(Theme.Colors.accentBlue.opacity(0.6))
                    .frame(width: geo.size.width)
                    .offset(x: geo.size.width * 0.22, y: geo.size.height * 0.35)
                    .blur(radius: 60)
            }
        }
        .allowsHitTesting(false)
    }

    var scrollContent: some View {
        VStack(spacing: Theme.Spacing.`4xl`) {
            headerSection
                .padding(.top, Theme.Spacing.`3xl`)

            badgesSection
                .padding(.bottom, Theme.Spacing.`4xl`)

            quickActionsSection
            topRecommendationsSection
        }
        .padding(.horizontal, Theme.Spacing.`2xl`)
        .padding(.bottom, 120)
    }

    // MARK: - Header
    var headerSection: some View {
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

            Menu {
                Button {
                    showAccountSettings = true
                } label: {
                    Label("Account Settings", systemImage: "gearshape.fill")
                }

                Button {
                    showAboutView = true
                } label: {
                    Label("About", systemImage: "info.circle")
                }

                Divider()

                Button(role: .destructive) {
                    showLogoutAlert = true
                } label: {
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
    }

    // MARK: - Badges
    var badgesSection: some View {
        HStack(spacing: Theme.Spacing.lg) {
            weatherBadge
            scheduleBadge
            moodBadge
        }
        .frame(maxWidth: .infinity)
    }

    var weatherBadge: some View {
        Group {
            if let weather = weatherManager.weather {
                Text("\(weather.emoji) \(weather.tempF)°F")
                    .themeFont(size: .base, weight: .semiBold)
                    .foregroundColor(Theme.Colors.textBlue)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Theme.Colors.accentBlue)
                    .cornerRadius(Theme.BorderRadius.md)
            } else {
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
                .cornerRadius(Theme.BorderRadius.md)
            }
        }
    }

    var scheduleBadge: some View {
        Text("Free until 6:30 PM")
            .themeFont(size: .base, weight: .semiBold)
            .foregroundColor(Theme.Colors.textPrimary)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colors.glassBackground)
            .cornerRadius(Theme.BorderRadius.md)
    }

    var moodBadge: some View {
        Text("Chill ✨")
            .themeFont(size: .base, weight: .semiBold)
            .foregroundColor(Theme.Colors.textSecondary)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colors.whiteOverlay)
            .cornerRadius(Theme.BorderRadius.md)
    }

    // MARK: - Quick Actions
    var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.`2xl`) {
            Text("Quick Actions")
                .themeFont(size: .`2xl`, weight: .bold)
                .foregroundColor(Theme.Colors.textPrimary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Theme.Spacing.md),
                    GridItem(.flexible(), spacing: Theme.Spacing.md)
                ],
                spacing: Theme.Spacing.xl
            ) {
                ForEach(QuickAction.allActions) { action in
                    QuickActionCard(action: action) {
                        selectedQuickAction = action.prompt
                    }
                }
            }
        }
    }

    // MARK: - Top Recommendations
    var topRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.`2xl`) {
            Text("Top Recommendations")
                .themeFont(size: .`2xl`, weight: .bold)
                .foregroundColor(Theme.Colors.textPrimary)

            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .padding()
            }

            if let err = viewModel.errorMessage {
                Text(err)
                    .foregroundColor(.red)
                    .padding(.vertical)
            }

            ForEach(viewModel.recommendations) { rec in
                RecommendationCard(
                    recommendation: rec,
                    session: session,
                    preferences: session.preferences
                ) {
                    let place = SelectedPlace(
                        name: rec.title,
                        latitude: rec.lat ?? 40.6942,
                        longitude: rec.lng ?? -73.9866,
                        walkTime: rec.walkTime,
                        distance: rec.distance,
                        address: rec.description,
                        image: rec.image
                    )

                    placeViewModel.setSelectedPlace(place)
                    tabCoordinator.selectedTab = .map
                }
            }
        }
    }
}

//
// MARK: - Backend Loading
//

private extension DashboardView {
    func loadDashboardData() async {
        print("📡 Loading dashboard data...")

        // 1. Weather
        await weatherManager.loadWeather()

        // 2. Recommendations
        await viewModel.loadTopRecommendations(
            jwt: session.jwt,
            preferences: session.preferences
        )

        // 3. 🔥 SEND RECOMMENDATION PINS TO MAP
        placeViewModel.nearbyPlaces = viewModel.recommendations.compactMap {
            guard let lat = $0.lat, let lng = $0.lng else { return nil }
            return SelectedPlace(
                name: $0.title,
                latitude: lat,
                longitude: lng,
                walkTime: $0.walkTime,
                distance: $0.distance,
                address: $0.description,
                image: $0.image
            )
        }
    }
}


//
// MARK: - QuickActionCard
//

struct QuickActionCard: View {
    let action: QuickAction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
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
                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                        .fill(.regularMaterial)

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
                }
            }
        }
        .buttonStyle(.plain)
    }
}

extension String: Identifiable {
    public var id: String { self }
}
