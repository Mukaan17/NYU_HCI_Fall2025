//
//  PermissionsView.swift
//  VioletVibes
//

import SwiftUI

struct PermissionsView: View {
    @Environment(OnboardingViewModel.self) private var onboardingViewModel
    
    @State private var locationPermission: Bool = false
    @State private var calendarPermission: Bool = false
    @State private var notificationPermission: Bool = false
    @State private var contactsPermission: Bool = false
    @State private var remindersPermission: Bool = false
    @State private var showScrollIndicator: Bool = true
    @State private var scrollOffset: CGFloat = 0
    
    private let locationService = LocationService.shared
    private let calendarService = CalendarService.shared
    private let notificationService = NotificationService.shared
    private let contactsService = ContactsService.shared
    private let remindersService = RemindersService.shared
    private let storage = StorageService.shared
    
    var body: some View {
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
                    .fill(Theme.Colors.gradientStart.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .offset(x: -50, y: -100)
                    .blur(radius: 60)
                
                Circle()
                    .fill(Theme.Colors.gradientStart.opacity(0.12))
                    .frame(width: 250, height: 250)
                    .offset(x: geometry.size.width - 200, y: geometry.size.height - 200)
                    .blur(radius: 50)
            }
            .allowsHitTesting(false)
            
            VStack(spacing: 0) {
                Spacer()
            
            ScrollView {
                    VStack(spacing: Theme.Spacing.`4xl`) {
                        // Permission Cards
                        VStack(spacing: Theme.Spacing.`4xl`) {
                            PermissionCard(
                                icon: "📍",
                                title: "Allow Location",
                                description: "To find awesome spots near you.",
                                isEnabled: locationPermission
                            )
                            
                            PermissionCard(
                                icon: "📅",
                                title: "Google Calendar Access",
                                description: "Allow VioletVibes to read your free time from Google Calendar to recommend events when you're available?",
                                isEnabled: calendarPermission
                            )
                            
                            PermissionCard(
                                icon: "🔔",
                                title: "Push Notifications",
                                description: "Enable notifications for personalized recommendations?",
                                isEnabled: notificationPermission
                            )
                            
                            PermissionCard(
                                icon: "👥",
                                title: "Access Contacts",
                                description: "To share recommendations with friends.",
                                isEnabled: contactsPermission
                            )
                            
                            PermissionCard(
                                icon: "📝",
                                title: "Access Reminders",
                                description: "To sync your to-do lists and reminders.",
                                isEnabled: remindersPermission
                            )
                        }
                        .padding(.horizontal, Theme.Spacing.`2xl`)
                        .padding(.top, Theme.Spacing.`6xl`)
                    
                        // Enable All Button
                    PrimaryButton(title: "Enable All") {
                        Task {
                            await requestAllPermissions()
                        }
                    }
                        .padding(.horizontal, Theme.Spacing.`2xl`)
                        .padding(.top, Theme.Spacing.`4xl`)
                        .padding(.bottom, Theme.Spacing.`6xl`)
                    }
                }
                .scrollIndicators(.hidden)
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                    }
                )
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                    // Hide indicator when user scrolls down
                    if value < -50 {
                        withAnimation {
                            showScrollIndicator = false
                        }
                    }
                }
                
                Spacer()
            }
            
            // Scroll Indicator
            if showScrollIndicator {
                VStack {
                    Spacer()
                    HStack {
                        ScrollIndicatorView()
                            .padding(.leading, Theme.Spacing.`2xl`)
                        Spacer()
                    }
                    .padding(.bottom, Theme.Spacing.`4xl`)
                }
                .transition(.opacity)
            }
        }
        .task {
            await checkPermissions()
        }
        .onAppear {
            // Hide indicator after 5 seconds if user hasn't scrolled
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if showScrollIndicator {
                    withAnimation {
                        showScrollIndicator = false
                    }
                }
            }
        }
    }
    
    private func checkPermissions() async {
        // Only check current permission status, don't request
        locationPermission = await locationService.checkPermissionStatus()
        calendarPermission = await calendarService.checkPermissionStatus()
        notificationPermission = await notificationService.checkPermissionStatus()
        contactsPermission = await contactsService.checkPermissionStatus()
        remindersPermission = await remindersService.checkPermissionStatus()
    }
    
    private func requestAllPermissions() async {
        let location = await locationService.requestPermission()
        let calendar = await calendarService.requestPermission()
        let notification = await notificationService.requestPermission()
        let contacts = await contactsService.requestPermission()
        let reminders = await remindersService.requestPermission()
        
        // Save permission states to UserPreferences
        var preferences = await storage.userPreferences
        preferences.googleCalendarEnabled = calendar
        preferences.notificationsEnabled = notification
        await storage.saveUserPreferences(preferences)
        
        await MainActor.run {
            locationPermission = location
            calendarPermission = calendar
            notificationPermission = notification
            contactsPermission = contacts
            remindersPermission = reminders
            
            if location || calendar || notification || contacts || reminders {
                onboardingViewModel.markPermissionsCompleted()
            }
        }
    }
}

// MARK: - Scroll Indicator View

struct ScrollIndicatorView: View {
    @State private var bounceOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Circle background with transparent liquid glass (matching permission tiles)
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 44, height: 44)
            
            // Chevron icon
            Image(systemName: "chevron.down")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.8))
                .offset(y: bounceOffset)
        }
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
            ) {
                bounceOffset = 4
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
