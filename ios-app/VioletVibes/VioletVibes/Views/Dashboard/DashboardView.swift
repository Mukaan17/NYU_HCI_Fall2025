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
    @Environment(AppStateManager.self) private var appStateManager
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
                            // Prefer dashboard weather, fallback to weatherManager
                            Group {
                            if let weather = viewModel.dashboardWeather ?? weatherManager.weather {
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
                                Text("\(weather.emoji) \(formatTemperature(weather.temp))°F")
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
                            
                            // Schedule Badge - System calendar free time
                            Button(action: {
                                // Always show calendar summary modal (shows system calendar events)
                                showCalendarSummary = true
                            }) {
                                Group {
                                    if calendarViewModel.isLoading {
                                        // Loading state
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(Theme.Colors.textPrimary)
                                    } else if let systemFreeTime = calendarViewModel.timeUntilFormatted(), !calendarViewModel.events.isEmpty {
                                        // System calendar has data
                                        Text(systemFreeTime)
                                            .themeFont(size: .base, weight: .semiBold)
                                            .foregroundColor(Theme.Colors.textPrimary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.75)
                                    } else if !calendarViewModel.events.isEmpty {
                                        // System calendar has events but no upcoming free time (all events are past or ongoing)
                                        Text("Free all day")
                                            .themeFont(size: .base, weight: .semiBold)
                                            .foregroundColor(Theme.Colors.textPrimary)
                                            .lineLimit(1)
                                    } else {
                                        // No events - free all day
                                        Text("Free all day")
                                            .themeFont(size: .base, weight: .semiBold)
                                            .foregroundColor(Theme.Colors.textPrimary)
                                            .lineLimit(1)
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.`2xl`)
                                .padding(.vertical, Theme.Spacing.md)
                                .frame(minHeight: 44) // Increased minimum height for better spacing
                                .background(Theme.Colors.glassBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.BorderRadius.full)
                                        .stroke(
                                            // Use full opacity if we have calendar data (system or Google), reduced if not linked
                                            (calendarViewModel.events.isEmpty && !viewModel.calendarLinked) ? Theme.Colors.border.opacity(0.5) : Theme.Colors.border,
                                            lineWidth: 1
                                        )
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
                        .padding(.bottom, Theme.Spacing.xl)
                        
                        // Free-Time Suggestion Card
                        if let suggestion = viewModel.freeTimeSuggestion, suggestion.should_suggest {
                            FreeTimeSuggestionCard(
                                suggestion: suggestion,
                                nextFree: viewModel.nextFreeBlock,
                                onViewDetails: {
                                    // Navigate to map with selected place
                                    let suggestionItem = suggestion.suggestion
                                    let place = SelectedPlace(
                                        name: suggestionItem.name ?? "Suggested Place",
                                        latitude: 40.693393, // Default if no location
                                        longitude: -73.98555,
                                        walkTime: nil,
                                        distance: nil,
                                        address: suggestionItem.address ?? suggestionItem.location,
                                        image: suggestionItem.photo_url
                                    )
                                    placeViewModel.setSelectedPlace(place)
                                    tabCoordinator.selectedTab = .map
                                },
                                onGetDirections: {
                                    // Open maps link
                                    let suggestionItem = suggestion.suggestion
                                    if let mapsLink = suggestionItem.maps_link, !mapsLink.isEmpty,
                                       let url = URL(string: mapsLink) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                        }
                        
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
                            // Show first 3 in the list, but all 10 are on the map
                            ForEach(Array(viewModel.recommendations.prefix(3))) { recommendation in
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
                Task { @MainActor in
                    await appStateManager.handleLogout(
                        userSession: session,
                        onboardingViewModel: onboardingViewModel
                    )
                }
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
        .sheet(isPresented: $showCalendarSummary) {
            // Calendar summary modal shows system calendar events (priority source)
            CalendarSummaryModal(
                events: calendarViewModel.events,
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
            let userLocation = locationManager.location
            await viewModel.loadRecommendations(
                jwt: session.jwt,
                preferences: session.preferences,
                weather: weatherString,
                vibe: vibeString,
                latitude: userLocation?.coordinate.latitude,
                longitude: userLocation?.coordinate.longitude
            )
            // Add recommendations to map
            addRecommendationsToMap(viewModel.recommendations)
        }
        .task {
            // Load weather on task start (app launch/restart)
            await weatherManager.loadWeather(locationManager: locationManager)
            
            // Load calendar events from system calendar
            await calendarViewModel.loadTodayEvents()
            
            // Load recommendations from backend
            let weatherString = weatherManager.weather?.emoji
            let vibeString = selectedVibe?.backendValue
            let userLocation = locationManager.location
            await viewModel.loadRecommendations(
                jwt: session.jwt,
                preferences: session.preferences,
                weather: weatherString,
                vibe: vibeString,
                latitude: userLocation?.coordinate.latitude,
                longitude: userLocation?.coordinate.longitude
            )
            // Add recommendations to map
            addRecommendationsToMap(viewModel.recommendations)
        }
        .onChange(of: locationManager.location) { oldValue, newValue in
            // Throttle weather and recommendations reloads - only reload if location changed significantly
            guard let newLocation = newValue else { return }
            
            if let oldLocation = oldValue {
                let distance = newLocation.distance(from: oldLocation)
                // Only reload if moved more than 200 meters to reduce API calls
                guard distance > 200 else { return }
            }
            
            // Reload weather and recommendations when location changes significantly
            Task {
                await weatherManager.loadWeather(locationManager: locationManager)
                let weatherString = weatherManager.weather?.emoji
                let vibeString = selectedVibe?.backendValue
                await viewModel.loadRecommendations(
                    jwt: session.jwt,
                    preferences: session.preferences,
                    weather: weatherString,
                    vibe: vibeString,
                    latitude: newLocation.coordinate.latitude,
                    longitude: newLocation.coordinate.longitude
                )
                // Add recommendations to map
                addRecommendationsToMap(viewModel.recommendations)
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
                    let userLocation = locationManager.location
                    await viewModel.loadRecommendations(
                        jwt: session.jwt,
                        preferences: session.preferences,
                        weather: weatherManager.weather?.emoji,
                        vibe: vibeString,
                        latitude: userLocation?.coordinate.latitude,
                        longitude: userLocation?.coordinate.longitude
                    )
                    // Add recommendations to map
                    addRecommendationsToMap(viewModel.recommendations)
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
                    
                    // Reload calendar events from system calendar
                    await calendarViewModel.loadTodayEvents()
                }
            }
        }
        .onChange(of: selectedVibe) { oldValue, newValue in
            // Reload recommendations when vibe changes
            Task {
                let weatherString = viewModel.dashboardWeather?.emoji ?? weatherManager.weather?.emoji
                let vibeString = newValue?.backendValue
                let userLocation = locationManager.location
                await viewModel.loadRecommendations(
                    jwt: session.jwt,
                    preferences: session.preferences,
                    weather: weatherString,
                    vibe: vibeString,
                    latitude: userLocation?.coordinate.latitude,
                    longitude: userLocation?.coordinate.longitude
                )
                // Add recommendations to map
                addRecommendationsToMap(viewModel.recommendations)
            }
        }
    }
    
    // Helper function to add recommendations to map as pins
    private func addRecommendationsToMap(_ recommendations: [Recommendation]) {
        // Map selected vibe to category for pin colors
        let category = mapVibeToCategory(selectedVibe?.backendValue)
        
        let places = recommendations.compactMap { recommendation -> SelectedPlace? in
            guard let lat = recommendation.lat, let lng = recommendation.lng else { return nil }
            return SelectedPlace(
                name: recommendation.title,
                latitude: lat,
                longitude: lng,
                walkTime: recommendation.walkTime,
                distance: recommendation.distance,
                address: recommendation.description,
                image: recommendation.image,
                rating: recommendation.popularity,
                category: category
            )
        }
        
        // Add all places to the map
        for place in places {
            placeViewModel.addPlace(place)
        }
    }
    
    // Map vibe to category for pin display
    private func mapVibeToCategory(_ vibe: String?) -> String? {
        guard let vibe = vibe else { return "explore" }
        
        switch vibe.lowercased() {
        case "explore":
            return "explore"
        case "food_general", "fast_bite":
            return "quick_bites"
        case "chill_drinks":
            return "chill_cafes"
        case "party":
            return "events"
        default:
            return "explore"
        }
    }
    
    // Helper function to format temperature (handles negative temperatures correctly)
    private func formatTemperature(_ temp: Int) -> String {
        // Int already handles negative values correctly, just convert to string
        return String(temp)
    }
    
    // Helper function to format free time block
    private func formatFreeTimeBlock(_ block: FreeTimeBlock) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let startDate = formatter.date(from: block.start),
              let endDate = formatter.date(from: block.end) else {
            return "Free time available"
        }
        
        let now = Date()
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "h:mm a"
        
        if startDate <= now && endDate > now {
            // Currently in free time block
            let endTime = timeFormatter.string(from: endDate)
            return "Free until \(endTime)"
        } else if startDate > now {
            // Future free time block
            let startTime = timeFormatter.string(from: startDate)
            let endTime = timeFormatter.string(from: endDate)
            return "Free \(startTime)-\(endTime)"
        } else {
            return "Free time available"
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


