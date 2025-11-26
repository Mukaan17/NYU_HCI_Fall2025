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
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(onboardingViewModel)
                .environment(chatViewModel)
                .environment(placeViewModel)
                .environment(locationManager)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @Environment(OnboardingViewModel.self) private var onboardingViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var isLoading = true
    
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
            } else {
                MainTabView()
            }
        }
        .task {
            await onboardingViewModel.checkOnboardingStatus()
            isLoading = false
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                // Schedule notification when app goes to background
                Task {
                    await scheduleBackgroundNotification()
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

