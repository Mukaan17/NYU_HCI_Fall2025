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
    
    private let locationService = LocationService.shared
    private let calendarService = CalendarService.shared
    private let notificationService = NotificationService.shared
    private let contactsService = ContactsService.shared
    private let remindersService = RemindersService.shared
    private let storage = StorageService.shared
    
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
                            
                            // Calendar Permission
                            PermissionToggleRow(
                                icon: "📅",
                                title: "Calendar",
                                description: "Find suggestions for your downtime",
                                isEnabled: $calendarPermission,
                                onToggle: { enabled in
                                    if enabled {
                                        Task {
                                            await requestCalendarPermission()
                                        }
                                    } else {
                                        showSettingsAlert(for: "Calendar")
                                    }
                                }
                            )
                            
                            // Notification Permission
                            PermissionToggleRow(
                                icon: "🔔",
                                title: "Notifications",
                                description: "Real-time alerts on events and deals",
                                isEnabled: $notificationPermission,
                                onToggle: { enabled in
                                    if enabled {
                                        Task {
                                            await requestNotificationPermission()
                                        }
                                    } else {
                                        showSettingsAlert(for: "Notifications")
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
                            Text("Home Address")
                                .themeFont(size: .`2xl`, weight: .bold)
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            Text("Used for safe route home feature")
                                .themeFont(size: .sm)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            TextField("Enter your home address", text: $homeAddress)
                                .themeFont(size: .base)
                                .foregroundColor(Theme.Colors.textPrimary)
                                .padding(Theme.Spacing.`2xl`)
                                .background(Theme.Colors.whiteOverlay)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                        .stroke(Theme.Colors.border, lineWidth: 1)
                                )
                                .cornerRadius(Theme.BorderRadius.md)
                            
                            Button(action: {
                                saveHomeAddress()
                            }) {
                                Text("Save Address")
                                    .themeFont(size: .base, weight: .semiBold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(Theme.Spacing.`2xl`)
                                    .background(
                                        LinearGradient(
                                            colors: [Theme.Colors.gradientStart, Theme.Colors.gradientEnd],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(Theme.BorderRadius.md)
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
            await storage.setHomeAddress(homeAddress.isEmpty ? nil : homeAddress)
        }
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

