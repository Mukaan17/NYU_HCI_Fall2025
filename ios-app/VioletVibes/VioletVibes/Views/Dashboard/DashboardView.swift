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
    @Environment(UserSession.self) private var session
    @Environment(PlaceViewModel.self) private var placeViewModel
    @Environment(TabCoordinator.self) private var tabCoordinator
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = DashboardViewModel()
    @State private var calendarViewModel = CalendarViewModel()
    @State private var navigateToCategory: String?
    @State private var showLogoutAlert = false
    @State private var showAboutView = false
    @State private var showAccountSettings = false
    @State private var selectedQuickAction: String?
    @State private var showCalendarSummary = false
    @State private var selectedVibe: VibeOption? = availableVibes.first
    @State private var isVibePickerExpanded = false
    @State private var isWeatherExpanded = false
    @State private var vibeButtonFrame: CGRect = .zero
    @State private var weatherButtonFrame: CGRect = .zero
    
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
                
                // Vibe picker overlay - positioned at top level to appear above everything
                VibePickerOverlay(
                    selectedVibe: $selectedVibe,
                    isExpanded: $isVibePickerExpanded,
                    buttonFrame: vibeButtonFrame
                )
                .allowsHitTesting(isVibePickerExpanded)
                .zIndex(10000) // Very high z-index to appear above Quick Actions cards
                
                // Weather dropdown overlay - positioned at top level to appear above everything
                WeatherDropdownOverlay(
                    currentWeather: weatherManager.weather,
                    forecast: weatherManager.forecast,
                    isExpanded: $isWeatherExpanded,
                    buttonFrame: weatherButtonFrame
                )
                .allowsHitTesting(isWeatherExpanded)
                .zIndex(10000) // Very high z-index to appear above Quick Actions cards
                
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
                            // Weather Badge - Clickable with loading state
                            Group {
                            if let weather = weatherManager.weather {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            isWeatherExpanded.toggle()
                                        }
                                        // Load forecast if not already loaded (in background, don't wait)
                                        if weatherManager.forecast == nil {
                                            Task {
                                                await weatherManager.loadForecast(locationManager: locationManager)
                                            }
                                        }
                                    }) {
                                Text("\(weather.emoji) \(weather.temp)°F")
                                    .themeFont(size: .base, weight: .semiBold)
                                    .foregroundColor(Theme.Colors.textBlue)
                                    .padding(.horizontal, Theme.Spacing.xl)
                                    .padding(.vertical, Theme.Spacing.sm)
                                            .frame(minHeight: 40) // Fixed minimum height
                                    .background(Theme.Colors.accentBlue)
                                    .overlay(
                                                RoundedRectangle(cornerRadius: Theme.BorderRadius.full)
                                            .stroke(Theme.Colors.accentBlueMedium, lineWidth: 1)
                                    )
                                            .cornerRadius(Theme.BorderRadius.full)
                                    }
                                    .buttonStyle(.plain)
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                    .background(
                                        GeometryReader { geometry in
                                            Color.clear
                                                .preference(key: WeatherButtonFrameKey.self, value: geometry.frame(in: .global))
                                        }
                                    )
                            } else {
                                    // Loading state
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
                                    .frame(minHeight: 40) // Fixed minimum height
                                .background(Theme.Colors.accentBlue)
                                .overlay(
                                        RoundedRectangle(cornerRadius: Theme.BorderRadius.full)
                                        .stroke(Theme.Colors.accentBlueMedium, lineWidth: 1)
                                )
                                    .cornerRadius(Theme.BorderRadius.full)
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                }
                            }
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: weatherManager.weather != nil)
                            .onPreferenceChange(WeatherButtonFrameKey.self) { frame in
                                weatherButtonFrame = frame
                            }
                            
                            // Schedule Badge - Clickable, shows calendar summary
                            Button(action: {
                                showCalendarSummary = true
                            }) {
                                Group {
                                    if calendarViewModel.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(Theme.Colors.textPrimary)
                                    } else if let freeTimeText = calendarViewModel.timeUntilFormatted() {
                                        Text(freeTimeText)
                                            .themeFont(size: .base, weight: .semiBold)
                                            .foregroundColor(Theme.Colors.textPrimary)
                                    } else {
                                        Text("Free all day")
                                .themeFont(size: .base, weight: .semiBold)
                                .foregroundColor(Theme.Colors.textPrimary)
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.xl)
                                .padding(.vertical, Theme.Spacing.sm)
                                .frame(minHeight: 40) // Fixed minimum height
                                .background(Theme.Colors.glassBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.BorderRadius.full)
                                        .stroke(Theme.Colors.border, lineWidth: 1)
                                )
                                .cornerRadius(Theme.BorderRadius.full)
                            }
                            .buttonStyle(.plain)
                            
                            // Vibe Badge - Dropdown picker (overlayed)
                            VibePickerDropdown(selectedVibe: $selectedVibe, isExpanded: $isVibePickerExpanded)
                        }
                        .frame(maxWidth: .infinity)
                        .onPreferenceChange(VibeButtonFrameKey.self) { frame in
                            vibeButtonFrame = frame
                        }
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
                                    QuickActionCard(action: action) {
                                        selectedQuickAction = action.prompt
                                    }
                                }
                            }
                        }
                        
                        // Recommendations
                        VStack(alignment: .leading, spacing: Theme.Spacing.`2xl`) {
                            Text("Top Recommendations")
                                .themeFont(size: .`2xl`, weight: .bold)
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            if viewModel.isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding()
                                    Spacer()
                                }
                            } else if viewModel.recommendations.isEmpty {
                                Text("No recommendations available")
                                    .themeFont(size: .base)
                                    .foregroundColor(Theme.Colors.textSecondary)
                                    .padding()
                            } else {
                            ForEach(viewModel.recommendations) { recommendation in
                                    RecommendationCard(recommendation: recommendation) {
                                        // Navigate to map and set selected place
                                        let place = SelectedPlace(
                                            name: recommendation.title,
                                            latitude: recommendation.lat ?? 40.693393,
                                            longitude: recommendation.lng ?? -73.98555,
                                            walkTime: recommendation.walkTime,
                                            distance: recommendation.distance,
                                            address: recommendation.description,
                                            image: recommendation.image
                                        )
                                        placeViewModel.setSelectedPlace(place)
                                        tabCoordinator.selectedTab = .map
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.`2xl`)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .scrollDisabled(isWeatherExpanded || isVibePickerExpanded) // Disable scrolling when overlays are open
                .scrollBounceBehavior(.basedOnSize)
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedQuickAction) { category in
                QuickResultsSheetView(category: category)
            }
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
        .sheet(isPresented: $showCalendarSummary) {
            CalendarSummaryModal(
                events: calendarViewModel.eventsUntilNext(),
                isPresented: $showCalendarSummary
            )
        }
        .refreshable {
            // Only allow refresh when overlays are closed
            guard !isWeatherExpanded && !isVibePickerExpanded else { return }
            
            // Pull to refresh - reload weather and recommendations
            await weatherManager.loadWeather(locationManager: locationManager)
            let weatherString = weatherManager.weather?.emoji
            let vibeString = selectedVibe?.backendValue
            await viewModel.loadRecommendations(
                jwt: session.jwt,
                preferences: session.preferences,
                weather: weatherString,
                vibe: vibeString
            )
        }
        .task {
            // Load weather on task start (app launch/restart)
            await weatherManager.loadWeather(locationManager: locationManager)
            
            // Load calendar events if calendar is linked
            if session.googleCalendarLinked {
                await calendarViewModel.loadTodayEvents(jwt: session.jwt)
            }
            
            // Load recommendations from backend
            let weatherString = weatherManager.weather?.emoji
            let vibeString = selectedVibe?.backendValue
            await viewModel.loadRecommendations(
                jwt: session.jwt,
                preferences: session.preferences,
                weather: weatherString,
                vibe: vibeString
            )
        }
        .onChange(of: locationManager.location) { oldValue, newValue in
            // Throttle weather reloads - only reload if location changed significantly
            guard let newLocation = newValue else { return }
            
            if let oldLocation = oldValue {
                let distance = newLocation.distance(from: oldLocation)
                // Only reload weather if moved more than 200 meters to reduce API calls
                guard distance > 200 else { return }
            }
            
            // Reload weather when location changes significantly
            Task {
                await weatherManager.loadWeather(locationManager: locationManager)
            }
        }
        .onAppear {
            // Close any open overlays when view appears
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isWeatherExpanded = false
                isVibePickerExpanded = false
            }
            
            // Ensure recommendations are loaded even if task fails
            if viewModel.recommendations.isEmpty {
                Task {
                    let vibeString = selectedVibe?.backendValue
                    await viewModel.loadRecommendations(
                        jwt: session.jwt,
                        preferences: session.preferences,
                        weather: weatherManager.weather?.emoji,
                        vibe: vibeString
                    )
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Reload weather and calendar when app comes to foreground
            if newPhase == .active && oldPhase != .active {
                print("🔄 Dashboard: App became active - reloading weather and calendar")
                locationManager.restartLocationUpdates()
                Task {
                    // Wait a bit for location to update, then load weather
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    await weatherManager.loadWeather(locationManager: locationManager)
                    
                    // Reload calendar events if calendar is linked
                    if session.googleCalendarLinked {
                        await calendarViewModel.loadTodayEvents(jwt: session.jwt)
                    }
                }
            }
        }
        .onChange(of: session.googleCalendarLinked) { oldValue, newValue in
            // Load calendar events when calendar link status changes
            if newValue {
                Task {
                    await calendarViewModel.loadTodayEvents(jwt: session.jwt)
                }
            }
        }
        .onChange(of: selectedVibe) { oldValue, newValue in
            // Reload recommendations when vibe changes
            Task {
                let weatherString = weatherManager.weather?.emoji
                let vibeString = newValue?.backendValue
                await viewModel.loadRecommendations(
                    jwt: session.jwt,
                    preferences: session.preferences,
                    weather: weatherString,
                    vibe: vibeString
                )
            }
        }
    }
}

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
        .buttonStyle(.plain)
    }
}


