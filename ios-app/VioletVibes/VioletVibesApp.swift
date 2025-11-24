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
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(onboardingViewModel)
                .environment(chatViewModel)
                .environment(placeViewModel)
                .environment(locationManager)
                .environment(weatherManager)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @Environment(OnboardingViewModel.self) private var onboardingViewModel
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var isLoading = true
    @State private var previousScenePhase: ScenePhase = .active
    
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
            } else if !onboardingViewModel.hasLoggedIn {
                LoginView()
            } else {
                MainTabView()
            }
        }
        .task {
            await onboardingViewModel.checkOnboardingStatus()
            isLoading = false
        }
        .onChange(of: scenePhase) { newPhase in
            let oldPhase = previousScenePhase
            previousScenePhase = newPhase
            
            if newPhase == .background {
                // Schedule notification when app goes to background
                Task {
                    await scheduleBackgroundNotification()
                }
            } else if newPhase == .active {
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
    
    private func scheduleBackgroundNotification() async {
        let notificationService = NotificationService.shared
        let message = "You're free till 8 PM — Live jazz at Fulton St starts soon (7 min walk)."
        await notificationService.scheduleNotification(
            title: "You're free till 8 PM!",
            body: message,
            timeInterval: 3.0 // Send 3 seconds after app goes to background
        )
    }
}

