//
//  AccountSettingsView.swift
//  VioletVibes
//

import SwiftUI
import CoreLocation
import EventKit
import UserNotifications
import UIKit

struct AccountSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var locationPermission: Bool = false
    @State private var calendarPermission: Bool = false
    @State private var notificationPermission: Bool = false
    @State private var contactsPermission: Bool = false
    @State private var remindersPermission: Bool = false
    @State private var homeAddress: String = ""
    @State private var isCheckingPermissions = false
    @State private var trustedContactsCount: Int = 0
    @State private var usePreferencesForPersonalization: Bool = true
    @State private var showChangePassword = false
    
    private let locationService = LocationService.shared
    private let calendarService = CalendarService.shared
    private let notificationService = NotificationService.shared
    private let contactsService = ContactsService.shared
    private let remindersService = RemindersService.shared
    private let storage = StorageService.shared
    private let api = APIService.shared
    @Environment(UserSession.self) private var userSession
    
    var body: some View {
        NavigationStack {
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
                        .fill(Theme.Colors.accentPurpleMedium.opacity(0.15))
                        .frame(width: geometry.size.width * 0.75, height: geometry.size.width * 0.75)
                        .offset(x: -geometry.size.width * 0.2, y: -100)
                        .blur(radius: 60)
                    
                    Circle()
                        .fill(Theme.Colors.accentBlue.opacity(0.12))
                        .frame(width: geometry.size.width * 0.6, height: geometry.size.width * 0.6)
                        .offset(x: geometry.size.width * 0.3, y: geometry.size.height * 0.5)
                        .blur(radius: 50)
                }
                .allowsHitTesting(false)
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.`4xl`) {
                        // Account Settings Section
                        AccountSettingsSectionView()
                            .padding(.horizontal, Theme.Spacing.`2xl`)
                            .padding(.top, Theme.Spacing.`3xl`)
                        
                        // Preferences Section
                        NavigationLink(destination: PreferencesView()) {
                            PreferencesSectionCardView()
                        }
                        .padding(.horizontal, Theme.Spacing.`2xl`)
                        
                        // Permissions Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.`2xl`) {
                            Text("Permissions")
                                .themeFont(size: .`2xl`, weight: .bold)
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            // Location Permission
                            PermissionToggleRow(
                                icon: "📍",
                                title: "Location",
                                description: "Find awesome spots near you",
                                isEnabled: $locationPermission,
                                onToggle: { enabled in
                                    if enabled {
                                        Task {
                                            await requestLocationPermission()
                                        }
                                    } else {
                                        // Show alert that user needs to disable in Settings
                                        showSettingsAlert(for: "Location")
                                    }
                                }
                            )
                            
                            // Google Calendar Permission
                            PermissionToggleRow(
                                icon: "📅",
                                title: "Google Calendar",
                                description: "Allow VioletVibes to read your free time from Google Calendar to recommend events when you're available?",
                                isEnabled: $calendarPermission,
                                onToggle: { enabled in
                                    if enabled {
                                        Task {
                                            await requestCalendarPermission()
                                            await saveCalendarPreference(enabled)
                                        }
                                    } else {
                                        Task {
                                            await saveCalendarPreference(false)
                                        }
                                        showSettingsAlert(for: "Calendar")
                                    }
                                }
                            )
                            
                            // Notification Permission
                            PermissionToggleRow(
                                icon: "🔔",
                                title: "Notifications",
                                description: "Enable notifications for personalized recommendations?",
                                isEnabled: $notificationPermission,
                                onToggle: { enabled in
                                    if enabled {
                                        Task {
                                            await requestNotificationPermission()
                                            await saveNotificationPreference(enabled)
                                        }
                                    } else {
                                        Task {
                                            await saveNotificationPreference(false)
                                        }
                                        showSettingsAlert(for: "Notifications")
                                    }
                                }
                            )
                            
                            // Use Preferences Toggle
                            PermissionToggleRow(
                                icon: "🎯",
                                title: "Use Preferences",
                                description: "Use preferences to personalize results",
                                isEnabled: $usePreferencesForPersonalization,
                                onToggle: { enabled in
                                    Task {
                                        await saveUsePreferencesPreference(enabled)
                                    }
                                }
                            )
                            
                            // Contacts Permission
                            PermissionToggleRow(
                                icon: "👥",
                                title: "Contacts",
                                description: "Share recommendations with friends",
                                isEnabled: $contactsPermission,
                                onToggle: { enabled in
                                    if enabled {
                                        Task {
                                            await requestContactsPermission()
                                        }
                                    } else {
                                        showSettingsAlert(for: "Contacts")
                                    }
                                }
                            )
                            
                            // Reminders Permission
                            PermissionToggleRow(
                                icon: "📝",
                                title: "Reminders",
                                description: "Sync your to-do lists and reminders",
                                isEnabled: $remindersPermission,
                                onToggle: { enabled in
                                    if enabled {
                                        Task {
                                            await requestRemindersPermission()
                                        }
                                    } else {
                                        showSettingsAlert(for: "Reminders")
                                    }
                                }
                            )
                        }
                        .padding(Theme.Spacing.`3xl`)
                        .background(Theme.Colors.glassBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.BorderRadius.lg)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                        .cornerRadius(Theme.BorderRadius.lg)
                        .padding(.horizontal, Theme.Spacing.`2xl`)
                        .padding(.top, Theme.Spacing.`3xl`)
                        
                        // Trusted Contacts Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                            HStack {
                                Text("Trusted Contacts")
                                    .themeFont(size: .`2xl`, weight: .bold)
                                    .foregroundColor(Theme.Colors.textPrimary)
                                
                                Spacer()
                                
                                if trustedContactsCount > 0 {
                                    Text("\(trustedContactsCount)")
                                        .themeFont(size: .base, weight: .semiBold)
                                        .foregroundColor(Theme.Colors.textSecondary)
                                        .padding(.horizontal, Theme.Spacing.md)
                                        .padding(.vertical, Theme.Spacing.xs)
                                        .background(Theme.Colors.gradientStart.opacity(0.2))
                                        .cornerRadius(Theme.BorderRadius.md)
                                }
                            }
                            
                            Text("Manage contacts who can receive your location")
                                .themeFont(size: .base)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            NavigationLink(destination: TrustedContactsView()) {
                                HStack {
                                    Text("Manage Trusted Contacts")
                                        .themeFont(size: .lg, weight: .semiBold)
                                        .foregroundColor(Theme.Colors.gradientStart)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                                .padding(Theme.Spacing.`2xl`)
                                .background(Theme.Colors.glassBackground)
                                .cornerRadius(Theme.BorderRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                        .stroke(Theme.Colors.border, lineWidth: 1)
                                )
                            }
                        }
                        .padding(Theme.Spacing.`3xl`)
                        .background(Theme.Colors.glassBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.BorderRadius.lg)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                        .cornerRadius(Theme.BorderRadius.lg)
                        .padding(.horizontal, Theme.Spacing.`2xl`)
                        .padding(.top, Theme.Spacing.`3xl`)
                        
                        // Home Address Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.`2xl`) {
                            HStack {
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text("Home Address")
                                        .themeFont(size: .`2xl`, weight: .bold)
                                        .foregroundColor(Theme.Colors.textPrimary)
                                    
                                    Text("Used for safe route home feature")
                                        .themeFont(size: .sm)
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                // Saved indicator
                                if !homeAddress.isEmpty {
                                    HStack(spacing: Theme.Spacing.xs) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Theme.Colors.accentGreen)
                                            .font(.system(size: 16))
                                        Text("Saved")
                                            .themeFont(size: .sm, weight: .medium)
                                            .foregroundColor(Theme.Colors.accentGreen)
                                    }
                                    .padding(.horizontal, Theme.Spacing.md)
                                    .padding(.vertical, Theme.Spacing.xs)
                                    .background(Theme.Colors.accentGreen.opacity(0.15))
                                    .cornerRadius(Theme.BorderRadius.md)
                                }
                            }
                            
                            // Address display or input
                            if !homeAddress.isEmpty {
                                // Show saved address with option to edit
                                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                                    HStack {
                                        Image(systemName: "house.fill")
                                            .foregroundColor(Theme.Colors.gradientStart)
                                            .font(.system(size: 18))
                                        
                                        Text(homeAddress)
                                            .themeFont(size: .base)
                                            .foregroundColor(Theme.Colors.textPrimary)
                                            .lineLimit(2)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            homeAddress = ""
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(Theme.Colors.textSecondary)
                                                .font(.system(size: 20))
                                        }
                                    }
                                    .padding(Theme.Spacing.`2xl`)
                                    .background(Theme.Colors.glassBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                            .stroke(Theme.Colors.border, lineWidth: 1)
                                    )
                                    .cornerRadius(Theme.BorderRadius.md)
                                    
                                    Button(action: {
                                        homeAddress = ""
                                    }) {
                                        Text("Change Address")
                                            .themeFont(size: .sm, weight: .medium)
                                            .foregroundColor(Theme.Colors.gradientStart)
                                    }
                                }
                            } else {
                                // Address input
                                LocationPickerView(address: $homeAddress, onAddressSelected: {
                                    // Auto-save when address is selected
                                    saveHomeAddress()
                                })
                            }
                        }
                        .padding(Theme.Spacing.`3xl`)
                        .background(Theme.Colors.glassBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.BorderRadius.lg)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                        .cornerRadius(Theme.BorderRadius.lg)
                        .padding(.horizontal, Theme.Spacing.`2xl`)
                        .padding(.bottom, Theme.Spacing.`4xl`)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Account Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.gradientStart)
                }
            }
            .task {
                await checkPermissions()
                await loadHomeAddress()
                await loadPreferences()
            }
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // Dismiss keyboard when tapping outside text fields
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
    
    private func checkPermissions() async {
        isCheckingPermissions = true
        
        // Check Location
        let locationStatus = locationService.authorizationStatus
        locationPermission = locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways
        
        // Check Calendar
        calendarPermission = calendarService.hasPermission
        
        // Check Notifications
        notificationPermission = await notificationService.hasPermission
        
        // Check Contacts
        contactsPermission = contactsService.hasPermission
        
        // Check Reminders
        remindersPermission = remindersService.hasPermission
        
        isCheckingPermissions = false
    }
    
    private func requestLocationPermission() async {
        let granted = await locationService.requestPermission()
        await MainActor.run {
            locationPermission = granted
        }
    }
    
    private func requestCalendarPermission() async {
        let granted = await calendarService.requestPermission()
        await MainActor.run {
            calendarPermission = granted
        }
    }
    
    private func requestNotificationPermission() async {
        let granted = await notificationService.requestPermission()
        await MainActor.run {
            notificationPermission = granted
        }
    }
    
    private func requestContactsPermission() async {
        let granted = await contactsService.requestPermission()
        await MainActor.run {
            contactsPermission = granted
        }
    }
    
    private func requestRemindersPermission() async {
        let granted = await remindersService.requestPermission()
        await MainActor.run {
            remindersPermission = granted
        }
    }
    
    private func showSettingsAlert(for permission: String) {
        // In a real app, you'd show an alert directing users to Settings
        // For now, we'll just update the toggle state
        print("User needs to disable \(permission) permission in Settings app")
    }
    
    private func loadHomeAddress() async {
        let address = await storage.homeAddress
        let contacts = await storage.trustedContacts
        await MainActor.run {
            homeAddress = address ?? ""
            trustedContactsCount = contacts.count
        }
    }
    
    private func saveHomeAddress() {
        Task {
            // Save to backend if user is logged in
            if let jwt = userSession.jwt {
                do {
                    _ = try await api.saveUserProfile(
                        firstName: nil, // Don't update first name here
                        homeAddress: homeAddress.isEmpty ? nil : homeAddress,
                        jwt: jwt
                    )
                    // Also save locally for offline access
                    await storage.setHomeAddress(homeAddress.isEmpty ? nil : homeAddress)
                    await MainActor.run {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                } catch {
                    print("Failed to save home address to backend: \(error)")
                    // Still save locally as fallback
                    await storage.setHomeAddress(homeAddress.isEmpty ? nil : homeAddress)
                }
            } else {
                // Not logged in, just save locally
                await storage.setHomeAddress(homeAddress.isEmpty ? nil : homeAddress)
            }
        }
    }
    
    private func loadPreferences() async {
        let preferences = await storage.userPreferences
        await MainActor.run {
            usePreferencesForPersonalization = preferences.usePreferencesForPersonalization
        }
    }
    
    private func saveCalendarPreference(_ enabled: Bool) async {
        var preferences = await storage.userPreferences
        preferences.googleCalendarEnabled = enabled
        await storage.saveUserPreferences(preferences)
    }
    
    private func saveNotificationPreference(_ enabled: Bool) async {
        var preferences = await storage.userPreferences
        preferences.notificationsEnabled = enabled
        await storage.saveUserPreferences(preferences)
    }
    
    private func saveUsePreferencesPreference(_ enabled: Bool) async {
        var preferences = await storage.userPreferences
        preferences.usePreferencesForPersonalization = enabled
        await storage.saveUserPreferences(preferences)
        await MainActor.run {
            usePreferencesForPersonalization = enabled
        }
    }
}

// MARK: - Account Settings Section View
struct AccountSettingsSectionView: View {
    @Environment(OnboardingViewModel.self) private var onboardingViewModel
    @Environment(UserSession.self) private var session
    @State private var firstName: String = ""
    @State private var showChangePassword = false
    @State private var showLogoutAlert = false
    private let storage = StorageService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.`2xl`) {
            Text("Account Settings")
                .themeFont(size: .`2xl`, weight: .bold)
                .foregroundColor(Theme.Colors.textPrimary)
            
            // First Name
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("First Name")
                    .themeFont(size: .sm, weight: .semiBold)
                    .foregroundColor(Theme.Colors.textSecondary)
                
                TextField("Enter your first name", text: $firstName)
                    .textContentType(.givenName)
                    .autocapitalization(.words)
                    .themeFont(size: .base)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(Theme.Spacing.`2xl`)
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                    .cornerRadius(Theme.BorderRadius.md)
                    .onChange(of: firstName) { oldValue, newValue in
                        saveFirstName(newValue)
                    }
            }
            
            // Change Password Button
            Button(action: {
                showChangePassword = true
            }) {
                HStack {
                    Text("Change Password")
                        .themeFont(size: .base, weight: .semiBold)
                        .foregroundColor(Theme.Colors.gradientStart)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(Theme.Spacing.`2xl`)
                .background(.ultraThinMaterial)
                .cornerRadius(Theme.BorderRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
            }
            
            // Logout Button
            Button(action: {
                showLogoutAlert = true
            }) {
                HStack {
                    Text("Logout")
                        .themeFont(size: .base, weight: .semiBold)
                        .foregroundColor(Theme.Colors.textError)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.square")
                        .foregroundColor(Theme.Colors.textError)
                }
                .padding(Theme.Spacing.`2xl`)
                .background(.ultraThinMaterial)
                .cornerRadius(Theme.BorderRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                        .stroke(Theme.Colors.accentErrorBorder, lineWidth: 1)
                )
            }
        }
        .padding(Theme.Spacing.`3xl`)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.BorderRadius.lg)
                    .fill(.regularMaterial)
                
                LinearGradient(
                    colors: [
                        Theme.Colors.gradientStart.opacity(0.1),
                        Theme.Colors.gradientEnd.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(Theme.BorderRadius.lg)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.BorderRadius.lg)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
        .task {
            await loadAccountInfo()
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
    
    private func loadAccountInfo() async {
        if let account = await storage.userAccount {
            await MainActor.run {
                firstName = account.firstName
            }
        }
    }
    
    private func saveFirstName(_ name: String) {
        Task {
            if var account = await storage.userAccount {
                account.firstName = name.trimmingCharacters(in: .whitespaces)
                await storage.saveUserAccount(account)
            }
        }
    }
    
    private func logout() {
        Task {
            // CRITICAL: Clear ALL current user's data before logging out to prevent state leakage
            await storage.clearCurrentUserHomeAddress()
            await storage.clearCurrentUserOnboardingStatus()
            await storage.clearCurrentUserPreferences()
            await storage.clearCurrentUserTrustedContacts()
            await storage.clearCurrentUserWelcomeStatus()
            await storage.clearCurrentUserPermissionsStatus()
            await storage.clearCurrentUserCalendarOAuthStatus()
            
            // CRITICAL: Clear user session to prevent state leakage
            await storage.clearUserSession()
            
            // Clear user account
            await storage.saveUserAccount(UserAccount(email: "", firstName: "", hasLoggedIn: false))
            await storage.setHasLoggedIn(false)
            
            await MainActor.run {
                // Clear session state
                session.jwt = nil
                session.googleCalendarLinked = false
                session.preferences = UserPreferences()
                session.settings = nil
                
                onboardingViewModel.hasLoggedIn = false
                onboardingViewModel.hasCompletedOnboardingSurvey = false
            }
        }
    }
}

// MARK: - Preferences Section Card View
struct PreferencesSectionCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.`2xl`) {
            HStack {
                Text("Preferences")
                    .themeFont(size: .`2xl`, weight: .bold)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            Text("Update your preferences for personalized recommendations")
                .themeFont(size: .base)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding(Theme.Spacing.`3xl`)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.BorderRadius.lg)
                    .fill(.regularMaterial)
                
                LinearGradient(
                    colors: [
                        Theme.Colors.gradientStart.opacity(0.1),
                        Theme.Colors.gradientEnd.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(Theme.BorderRadius.lg)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.BorderRadius.lg)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
}

struct PermissionToggleRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: Theme.Spacing.`2xl`) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                    .fill(Theme.Colors.whiteOverlayMedium)
                    .frame(width: 48, height: 48)
                
                Text(icon)
                    .font(.system(size: 24))
            }
            
            // Text
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .themeFont(size: .base, weight: .semiBold)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text(description)
                    .themeFont(size: .sm)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { newValue in
                    onToggle(newValue)
                }
            ))
            .tint(Theme.Colors.gradientStart)
        }
    }
}

