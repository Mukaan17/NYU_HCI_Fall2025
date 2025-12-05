//
//  VioletVibesApp.swift
//  VioletVibes
//
//  Created on 2025
//

import SwiftUI

@main
struct VioletVibesApp: App {
    @State private var onboardingViewModel = OnboardingViewModel()
    @State private var chatViewModel = ChatViewModel()
    @State private var placeViewModel = PlaceViewModel()
    @State private var locationManager = LocationManager()
    @State private var weatherManager = WeatherManager()
    @State private var userSession = UserSession()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(onboardingViewModel)
                .environment(chatViewModel)
                .environment(placeViewModel)
                .environment(locationManager)
                .environment(weatherManager)
                .environment(userSession)
                .preferredColorScheme(.dark)
                .task {
                    // Load session on app start - this restores JWT from local storage
                    let storage = StorageService.shared
                    let loadedSession = await storage.loadUserSession()
                    await MainActor.run {
                        userSession.jwt = loadedSession.jwt
                    }
                }
        }
    }
}

struct RootView: View {
    @Environment(OnboardingViewModel.self) private var onboardingViewModel
    @Environment(LocationManager.self) private var locationManager
    @Environment(UserSession.self) private var userSession
    @Environment(\.scenePhase) private var scenePhase
    @State private var isLoading = true
    @State private var previousScenePhase: ScenePhase = .active
    private let calendarNotificationService = CalendarNotificationService.shared
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.Colors.background)
            } else if !onboardingViewModel.hasSeenWelcome {
                WelcomeView()
            } else if !onboardingViewModel.hasCompletedPermissions {
                PermissionsView()
            } else if userSession.jwt == nil {
                // Only show login if no JWT token exists (user not logged in)
                LoginView()
            } else if !onboardingViewModel.hasCompletedOnboardingSurvey {
                OnboardingSurveyView()
            } else {
                MainTabView()
            }
        }
        .task {
            await onboardingViewModel.checkOnboardingStatus()
            
            // If user has a JWT token, they're logged in - update onboarding status
            if userSession.jwt != nil {
                await MainActor.run {
                    onboardingViewModel.hasLoggedIn = true
                }
            }
            
            isLoading = false
            
            // Start calendar notification monitoring if user is logged in
            if let jwt = userSession.jwt {
                calendarNotificationService.startMonitoring(jwt: jwt)
            }
        }
        .onChange(of: userSession.jwt) { oldValue, newValue in
            // Update onboarding status when JWT is loaded
            if newValue != nil {
                Task { @MainActor in
                    onboardingViewModel.hasLoggedIn = true
                }
            }
            
            // Start/stop monitoring when JWT changes
            if let jwt = newValue {
                calendarNotificationService.startMonitoring(jwt: jwt)
            } else {
                calendarNotificationService.stopMonitoring()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            let oldPhase = previousScenePhase
            previousScenePhase = newPhase
            
            if newPhase == .active {
                // Swift 6.2: App became active - use TaskGroup to coordinate location and weather
                if oldPhase == .inactive || oldPhase == .background {
                    print("🔄 App became active from \(oldPhase) - coordinating location check and weather loading")
                    Task {
                        // Small delay to ensure app is fully active
                        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                        
                        // Use TaskGroup to coordinate location check
                        await withTaskGroup(of: Void.self) { group in
                            // Task 1: Force location check
                            group.addTask {
                                await MainActor.run {
                                    self.locationManager.forceLocationCheck()
                                }
                            }
                            
                            // Task 2: Wait for location, then trigger weather reload
                            group.addTask {
                                // Wait a bit for location to update
                                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                                
                                // Location check should be done by now
                                // Weather loading will be triggered by onChange handlers in views
                            }
                            
                            // Wait for tasks to complete
                            for await _ in group {}
                        }
                    }
                }
            }
        }
    }
}

