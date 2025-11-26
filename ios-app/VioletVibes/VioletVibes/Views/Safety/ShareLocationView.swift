//
//  ShareLocationView.swift
//  VioletVibes
//

import SwiftUI
import CoreLocation
import UIKit
import Contacts
import ContactsUI

struct ShareLocationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LocationManager.self) private var locationManager
    @State private var trustedContacts: [TrustedContact] = []
    @State private var isSharing = false
    @State private var sharingContact: TrustedContact?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingContactPicker = false
    
    private let storage = StorageService.shared
    private let sharingService = LocationSharingService.shared
    private let contactsService = ContactsService.shared
    
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
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: Theme.Spacing.lg) {
                        Text("Share Live Location")
                            .themeFont(size: .`3xl`, weight: .bold)
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Text("Select contacts to share your current location with")
                            .themeFont(size: .base)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Theme.Spacing.`4xl`)
                    .padding(.horizontal, Theme.Spacing.`2xl`)
                    
                    // Current Location Status
                    if let location = locationManager.location {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "location.fill")
                                .foregroundColor(Theme.Colors.gradientStart)
                            Text("Location available")
                                .themeFont(size: .sm)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        .padding(.top, Theme.Spacing.lg)
                    } else {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "location.slash")
                                .foregroundColor(Theme.Colors.accentError)
                            Text("Location unavailable")
                                .themeFont(size: .sm)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        .padding(.top, Theme.Spacing.lg)
                    }
                    
                    // Contacts List
                    if trustedContacts.isEmpty {
                        Spacer()
                        VStack(spacing: Theme.Spacing.lg) {
                            Image(systemName: "person.2.circle")
                                .font(.system(size: 60))
                                .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
                            
                            Text("No Trusted Contacts")
                                .themeFont(size: .xl, weight: .semiBold)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            Text("Add trusted contacts to share your location")
                                .themeFont(size: .base)
                                .foregroundColor(Theme.Colors.textSecondary.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, Theme.Spacing.`4xl`)
                        Spacer()
                    } else {
                        List {
                            ForEach(trustedContacts) { contact in
                                ShareContactRow(
                                    contact: contact,
                                    isSharing: isSharing && sharingContact?.id == contact.id,
                                    onShare: {
                                        shareLocation(with: contact)
                                    }
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(
                                    top: Theme.Spacing.xs,
                                    leading: Theme.Spacing.`2xl`,
                                    bottom: Theme.Spacing.xs,
                                    trailing: Theme.Spacing.`2xl`
                                ))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        removeContact(contact)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .padding(.vertical, Theme.Spacing.`2xl`)
                    }
                    
                    // Action Buttons
                    VStack(spacing: Theme.Spacing.md) {
                        if !trustedContacts.isEmpty {
                            PrimaryButton(
                                title: "Share with All",
                                disabled: isSharing || locationManager.location == nil
                            ) {
                                shareWithAll()
                            }
                        }
                        
                        Button(action: {
                            requestContactsPermissionAndShowPicker()
                        }) {
                            Text("Add More Contacts")
                                .themeFont(size: .lg, weight: .semiBold)
                                .foregroundColor(Theme.Colors.gradientStart)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.`2xl`)
                    .padding(.bottom, Theme.Spacing.`2xl`)
                }
            }
            .navigationTitle("Share Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.gradientStart)
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerWrapper(
                    onContactSelected: { contact in
                        addContact(contact)
                    },
                    isPresented: $showingContactPicker
                )
            }
            .task {
                await loadContacts()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func loadContacts() async {
        let contacts = await storage.trustedContacts
        await MainActor.run {
            trustedContacts = contacts
        }
    }
    
    private func requestContactsPermissionAndShowPicker() {
        Task {
            let hasPermission = await contactsService.requestPermission()
            await MainActor.run {
                if hasPermission {
                    showingContactPicker = true
                } else {
                    errorMessage = "Contacts permission is required to add trusted contacts"
                    showingError = true
                }
            }
        }
    }
    
    private func addContact(_ contact: TrustedContact) {
        Task {
            do {
                try await storage.addTrustedContact(contact)
                await loadContacts()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func removeContact(_ contact: TrustedContact) {
        Task {
            await storage.removeTrustedContact(contact.id)
            await loadContacts()
        }
    }
    
    private func shareLocation(with contact: TrustedContact) {
        guard let location = locationManager.location else {
            errorMessage = "Unable to get your current location"
            showingError = true
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to share location"
            showingError = true
            return
        }
        
        // Find the topmost view controller
        var topViewController = rootViewController
        while let presented = topViewController.presentedViewController {
            topViewController = presented
        }
        
        isSharing = true
        sharingContact = contact
        
        sharingService.shareLocation(
            with: contact,
            location: location,
            presentingViewController: topViewController
        ) { success, message in
            DispatchQueue.main.async {
                isSharing = false
                sharingContact = nil
                if !success {
                    errorMessage = message ?? "Unable to share location"
                    showingError = true
                }
            }
        }
    }
    
    private func shareWithAll() {
        guard let location = locationManager.location else {
            errorMessage = "Unable to get your current location"
            showingError = true
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to share location"
            showingError = true
            return
        }
        
        var topViewController = rootViewController
        while let presented = topViewController.presentedViewController {
            topViewController = presented
        }
        
        isSharing = true
        
        // Share with all contacts sequentially
        for (index, contact) in trustedContacts.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.5) {
                sharingContact = contact
                sharingService.shareLocation(
                    with: contact,
                    location: location,
                    presentingViewController: topViewController
                ) { success, message in
                    if index == trustedContacts.count - 1 {
                        DispatchQueue.main.async {
                            isSharing = false
                            sharingContact = nil
                        }
                    }
                }
            }
        }
    }
}

// MARK: - ShareContactRow

struct ShareContactRow: View {
    let contact: TrustedContact
    let isSharing: Bool
    let onShare: () -> Void
    
    var body: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Theme.Colors.gradientStart.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(String(contact.name.prefix(1)).uppercased())
                    .themeFont(size: .lg, weight: .bold)
                    .foregroundColor(Theme.Colors.gradientStart)
            }
            
            // Contact Info
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(contact.name)
                    .themeFont(size: .lg, weight: .semiBold)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                if !contact.displayInfo.isEmpty {
                    Text(contact.displayInfo)
                        .themeFont(size: .sm)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            // Share Button
            Button(action: onShare) {
                if isSharing {
                    ProgressView()
                        .tint(.white)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.md)
                } else {
                    Text("Share")
                        .themeFont(size: .base, weight: .semiBold)
                        .foregroundColor(.white)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.md)
                }
            }
            .background(
                LinearGradient(
                    colors: [Theme.Colors.gradientStart, Theme.Colors.gradientEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(Theme.BorderRadius.md)
            .disabled(isSharing)
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

