//
//  PermissionsView.swift
//  VioletVibes
//

import SwiftUI

struct PermissionsView: View {
    @Environment(OnboardingViewModel.self) private var onboardingViewModel
    @Environment(UserSession.self) private var session
    
    @State private var locationPermission: Bool = false
    @State private var notificationPermission: Bool = false
    @State private var contactsPermission: Bool = false
    @State private var remindersPermission: Bool = false
    
    @State private var showScrollIndicator: Bool = true
    
    private let locationService = LocationService.shared
    private let notificationService = NotificationService.shared
    private let contactsService = ContactsService.shared
    private let remindersService = RemindersService.shared
    
    var body: some View {
        ZStack {
            // Background Gradient
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
            
            VStack(spacing: 0) {
                Spacer()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.`4xl`) {
                        
                        // ---------------------------------------------------------
                        // PERMISSION CARDS
                        // ---------------------------------------------------------
                        PermissionCard(
                            icon: "📍",
                            title: "Allow Location",
                            description: "To find great spots near you.",
                            isEnabled: locationPermission
                        )
                        
                        PermissionCard(
                            icon: "📅",
                            title: "Google Calendar Access",
                            description: "Connect so VioletVibes can read your free time.",
                            isEnabled: session.googleCalendarLinked == true
                        )
                        
                        PermissionCard(
                            icon: "🔔",
                            title: "Push Notifications",
                            description: "Enable notifications for personalized recommendations.",
                            isEnabled: notificationPermission
                        )
                        
                        PermissionCard(
                            icon: "👥",
                            title: "Contacts Access",
                            description: "To share recommendations with friends.",
                            isEnabled: contactsPermission
                        )
                        
                        PermissionCard(
                            icon: "📝",
                            title: "Reminders Access",
                            description: "To sync your to-do lists.",
                            isEnabled: remindersPermission
                        )
                        
                        // ENABLE ALL BUTTON
                        PrimaryButton(title: "Enable All") {
                            Task { await enableAll() }
                        }
                        .padding(.top, Theme.Spacing.`4xl`)
                        .padding(.bottom, Theme.Spacing.`6xl`)
                        
                    }
                    .padding(.horizontal, Theme.Spacing.`2xl`)
                    .padding(.top, Theme.Spacing.`6xl`)
                }
                .scrollIndicators(.hidden)
                
                Spacer()
            }
        }
        .task { await loadCurrentState() }
        .onAppear { hideIndicatorAfterDelay() }
    }
    
    
    // ------------------------------------------------------------
    // MARK: - Google OAuth
    // ------------------------------------------------------------
    private func openGoogleCalendarOAuth() {
        guard let jwt = session.jwt else {
            print("❌ Missing JWT for Google OAuth")
            return
        }
        
        let raw = "\(APIService.serverURL)/api/calendar/oauth/google/start?token=\(jwt)"
        guard let url = URL(string: raw) else {
            print("❌ Invalid Google OAuth URL")
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    
    // ------------------------------------------------------------
    // MARK: - Initial Load
    // ------------------------------------------------------------
    private func loadCurrentState() async {
        // These return true/false based on system permission state
        locationPermission = await locationService.requestPermission()
        notificationPermission = await notificationService.requestPermission()
        contactsPermission = await contactsService.requestPermission()
        remindersPermission = await remindersService.requestPermission()
        
        // Calendar is backend-only; session.googleCalendarLinked already tracks it
    }
    
    
    // ------------------------------------------------------------
    // MARK: - Enable All
    // ------------------------------------------------------------
    private func enableAll() async {
        let loc = await locationService.requestPermission()
        let notif = await notificationService.requestPermission()
        let cont = await contactsService.requestPermission()
        let rem = await remindersService.requestPermission()
        
        // Trigger Google OAuth (Web pop-up)
        openGoogleCalendarOAuth()
        
        await MainActor.run {
            locationPermission = loc
            notificationPermission = notif
            contactsPermission = cont
            remindersPermission = rem
            
            onboardingViewModel.markPermissionsCompleted()
        }
    }
    
    
    // ------------------------------------------------------------
    // MARK: - Scroll Indicator Hide Delay
    // ------------------------------------------------------------
    private func hideIndicatorAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation { showScrollIndicator = false }
        }
    }
}
