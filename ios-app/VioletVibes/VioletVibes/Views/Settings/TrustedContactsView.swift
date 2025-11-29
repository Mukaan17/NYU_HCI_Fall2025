//
//  TrustedContactsView.swift
//  VioletVibes
//

import SwiftUI
import Contacts
import ContactsUI

struct TrustedContactsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var trustedContacts: [TrustedContact] = []
    @State private var showingContactPicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let storage = StorageService.shared
    private let contactsService = ContactsService.shared
    
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
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: Theme.Spacing.lg) {
                    Text("Trusted Contacts")
                        .themeFont(size: .`3xl`, weight: .bold)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text("Manage contacts who can receive your location")
                        .themeFont(size: .base)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Spacing.`4xl`)
                .padding(.horizontal, Theme.Spacing.`2xl`)
                
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
                        
                        Text("Add contacts to share your location with")
                            .themeFont(size: .base)
                            .foregroundColor(Theme.Colors.textSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, Theme.Spacing.`4xl`)
                    Spacer()
                } else {
                    List {
                        ForEach(trustedContacts) { contact in
                            TrustedContactRow(contact: contact) {
                                removeContact(contact)
                            }
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
                }
                
                // Add Button
                PrimaryButton(title: "Add Contact") {
                    requestContactsPermissionAndShowPicker()
                }
                .padding(.horizontal, Theme.Spacing.`2xl`)
                .padding(.bottom, Theme.Spacing.`2xl`)
            }
        }
        .navigationTitle("Trusted Contacts")
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
}

// MARK: - TrustedContactRow

struct TrustedContactRow: View {
    let contact: TrustedContact
    let onDelete: () -> Void
    
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

// MARK: - ContactPickerWrapper

struct ContactPickerWrapper: View {
    let onContactSelected: (TrustedContact) -> Void
    @Binding var isPresented: Bool
    
    var body: some View {
        ContactPickerPresenter(
            onContactSelected: { contact in
                onContactSelected(contact)
                // Dismiss this sheet only, not the parent
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPresented = false
                }
            },
            onDismiss: {
                // Dismiss this sheet only, not the parent
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPresented = false
                }
            }
        )
    }
}

// MARK: - ContactPickerPresenter

struct ContactPickerPresenter: UIViewControllerRepresentable {
    let onContactSelected: (TrustedContact) -> Void
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let container = UIViewController()
        
        // Present the contact picker when the view appears
        DispatchQueue.main.async {
            let picker = CNContactPickerViewController()
            picker.delegate = context.coordinator
            container.present(picker, animated: true)
        }
        
        return container
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPickerPresenter
        
        init(_ parent: ContactPickerPresenter) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let trustedContact = TrustedContact(
                name: "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces),
                phoneNumber: contact.phoneNumbers.first?.value.stringValue,
                email: contact.emailAddresses.first?.value as String?
            )
            parent.onContactSelected(trustedContact)
            picker.dismiss(animated: true) {
                self.parent.onDismiss()
            }
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            picker.dismiss(animated: true) {
                self.parent.onDismiss()
            }
        }
    }
}

