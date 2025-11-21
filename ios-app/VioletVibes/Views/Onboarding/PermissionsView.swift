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
    
    private let locationService = LocationService.shared
    private let calendarService = CalendarService.shared
    private let notificationService = NotificationService.shared
    
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
                                title: "Sync Calendar",
                                description: "To find suggestions for your downtime.",
                                isEnabled: calendarPermission
                            )
                            
                            PermissionCard(
                                icon: "🔔",
                                title: "Enable Notifications",
                                description: "For real-time alerts on events and deals.",
                                isEnabled: notificationPermission
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
                
                Spacer()
            }
        }
        .task {
            await checkPermissions()
        }
    }
    
    private func checkPermissions() async {
        locationPermission = await locationService.requestPermission()
        calendarPermission = await calendarService.requestPermission()
        notificationPermission = await notificationService.requestPermission()
    }
    
    private func requestAllPermissions() async {
        let location = await locationService.requestPermission()
        let calendar = await calendarService.requestPermission()
        let notification = await notificationService.requestPermission()
        
        await MainActor.run {
            locationPermission = location
            calendarPermission = calendar
            notificationPermission = notification
            
            if location || calendar || notification {
                onboardingViewModel.markPermissionsCompleted()
            }
        }
    }
}
