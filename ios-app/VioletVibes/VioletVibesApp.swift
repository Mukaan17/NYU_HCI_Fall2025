//
//  VioletVibesApp.swift
//  VioletVibes
//
//  Created on 2025
//

import SwiftUI

@main
struct VioletVibesApp: App {
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var placeViewModel = PlaceViewModel()
    @StateObject private var locationManager = LocationManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(onboardingViewModel)
                .environmentObject(chatViewModel)
                .environmentObject(placeViewModel)
                .environmentObject(locationManager)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
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
    }
}

