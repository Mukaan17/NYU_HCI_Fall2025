//
//  PermissionsView.swift
//  VioletVibes
//

import SwiftUI

struct PermissionsView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Text("Permissions")
                        .themeFont(size: .`3xl`, weight: .bold)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .padding(.top, Theme.Spacing.`6xl`)
                    
                    Text("Location: \(locationPermission ? "Enabled" : "Disabled")")
                        .themeFont(size: .base)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Text("Calendar: \(calendarPermission ? "Enabled" : "Disabled")")
                        .themeFont(size: .base)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Text("Notifications: \(notificationPermission ? "Enabled" : "Disabled")")
                        .themeFont(size: .base)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    PrimaryButton(title: "Enable All") {
                        Task {
                            await requestAllPermissions()
                        }
                    }
                    .padding(.top, Theme.Spacing.`2xl`)
                }
                .padding(Theme.Spacing.lg)
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

