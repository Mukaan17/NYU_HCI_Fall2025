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

    // ⭐ GLOBAL USER SESSION
    @State private var session = UserSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(onboardingViewModel)
                .environment(chatViewModel)
                .environment(placeViewModel)
                .environment(locationManager)
                .environment(weatherManager)
                .environment(session)      // ⭐ inject everywhere
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {

    @Environment(OnboardingViewModel.self) private var onboardingViewModel
    @Environment(LocationManager.self) private var locationManager
    @Environment(UserSession.self) private var session     // ⭐ READ GLOBAL SESSION

    @Environment(\.scenePhase) private var scenePhase

    @State private var isLoading: Bool = true
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

            } else if !onboardingViewModel.hasCompletedOnboardingSurvey {
                OnboardingSurveyView()

            } else {
                MainTabView()
            }
        }
        .task {
            let storage = StorageService.shared

            // 1) Load onboarding flags
            await onboardingViewModel.checkOnboardingStatus()

            // 2) Load preferences
            let savedPrefs = await storage.userPreferences

            // 3) Load saved session (jwt + calendarLinked)
            let savedSession = await storage.loadUserSession()

            await MainActor.run {
                // apply loaded values
                session.preferences = savedPrefs
                session.jwt = savedSession.jwt
                session.googleCalendarLinked = savedSession.googleCalendarLinked
            }

            isLoading = false
        }

        .onChange(of: scenePhase) { newPhase in
            let old = previousScenePhase
            previousScenePhase = newPhase

            if newPhase == .background {
                Task {
                    await scheduleBackgroundNotification()
                }

            } else if newPhase == .active {
                if old == .inactive || old == .background {
                    Task {
                        try? await Task.sleep(nanoseconds: 300_000_000)

                        await withTaskGroup(of: Void.self) { group in

                            group.addTask {
                                await MainActor.run {
                                    self.locationManager.forceLocationCheck()
                                }
                            }

                            group.addTask {
                                try? await Task.sleep(nanoseconds: 1_000_000_000)
                            }

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
            timeInterval: 3.0
        )
    }
}
