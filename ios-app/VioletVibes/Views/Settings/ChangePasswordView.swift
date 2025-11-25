//
//  ChangePasswordView.swift
//  VioletVibes
//

import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isCurrentPasswordValid: Bool = false
    @State private var isNewPasswordValid: Bool = false
    @State private var isConfirmPasswordValid: Bool = false
    @State private var isChanging = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
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
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.`4xl`) {
                        Spacer()
                            .frame(height: 40)
                        
                        // Title
                        VStack(spacing: Theme.Spacing.sm) {
                            Text("Change Password")
                                .themeFont(size: .`3xl`, weight: .bold)
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            Text("Enter your current and new password")
                                .themeFont(size: .lg)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        
                        // Current Password Field
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Current Password")
                                .themeFont(size: .sm, weight: .semiBold)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            SecureField("Enter current password", text: $currentPassword)
                                .textContentType(.password)
                                .themeFont(size: .base)
                                .foregroundColor(Theme.Colors.textPrimary)
                                .padding(Theme.Spacing.`2xl`)
                                .background(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                        .stroke(isCurrentPasswordValid && !currentPassword.isEmpty ? Theme.Colors.gradientStart.opacity(0.3) : Theme.Colors.border, lineWidth: 1)
                                )
                                .cornerRadius(Theme.BorderRadius.md)
                                .onChange(of: currentPassword) { oldValue, newValue in
                                    let sanitized = sanitizePassword(newValue)
                                    if sanitized != newValue {
                                        currentPassword = sanitized
                                    }
                                    isCurrentPasswordValid = validatePassword(sanitized)
                                }
                        }
                        
                        // New Password Field
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("New Password")
                                .themeFont(size: .sm, weight: .semiBold)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            SecureField("Enter new password", text: $newPassword)
                                .textContentType(.newPassword)
                                .themeFont(size: .base)
                                .foregroundColor(Theme.Colors.textPrimary)
                                .padding(Theme.Spacing.`2xl`)
                                .background(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                        .stroke(isNewPasswordValid && !newPassword.isEmpty ? Theme.Colors.gradientStart.opacity(0.3) : Theme.Colors.border, lineWidth: 1)
                                )
                                .cornerRadius(Theme.BorderRadius.md)
                                .onChange(of: newPassword) { oldValue, newValue in
                                    let sanitized = sanitizePassword(newValue)
                                    if sanitized != newValue {
                                        newPassword = sanitized
                                    }
                                    isNewPasswordValid = validatePassword(sanitized)
                                    isConfirmPasswordValid = validatePassword(confirmPassword) && sanitized == confirmPassword
                                }
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Confirm New Password")
                                .themeFont(size: .sm, weight: .semiBold)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            SecureField("Confirm new password", text: $confirmPassword)
                                .textContentType(.newPassword)
                                .themeFont(size: .base)
                                .foregroundColor(Theme.Colors.textPrimary)
                                .padding(Theme.Spacing.`2xl`)
                                .background(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                        .stroke(isConfirmPasswordValid && !confirmPassword.isEmpty ? Theme.Colors.gradientStart.opacity(0.3) : Theme.Colors.border, lineWidth: 1)
                                )
                                .cornerRadius(Theme.BorderRadius.md)
                                .onChange(of: confirmPassword) { oldValue, newValue in
                                    let sanitized = sanitizePassword(newValue)
                                    if sanitized != newValue {
                                        confirmPassword = sanitized
                                    }
                                    isConfirmPasswordValid = validatePassword(sanitized) && sanitized == newPassword
                                }
                        }
                        
                        // Change Password Button
                        Button(action: {
                            changePassword()
                        }) {
                            HStack {
                                if isChanging {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Change Password")
                                        .themeFont(size: .lg, weight: .bold)
                                        .foregroundColor(Theme.Colors.textPrimary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.lg)
                            .background(
                                LinearGradient(
                                    colors: [Theme.Colors.gradientStart, Theme.Colors.gradientEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(Theme.BorderRadius.md)
                        }
                        .disabled(isChanging || !isCurrentPasswordValid || !isNewPasswordValid || !isConfirmPasswordValid)
                        .opacity((isChanging || !isCurrentPasswordValid || !isNewPasswordValid || !isConfirmPasswordValid) ? 0.5 : 1.0)
                        
                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal, Theme.Spacing.`2xl`)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.gradientStart)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Password changed successfully")
            }
        }
    }
    
    // MARK: - Validation Functions
    
    private func sanitizePassword(_ input: String) -> String {
        let dangerousChars = CharacterSet(charactersIn: "<>'\"\\`|{}[];:=&$#*?~")
        var allowedChars = CharacterSet.alphanumerics
        allowedChars.insert(charactersIn: " !@%^()_+-.,/")
        allowedChars.subtract(dangerousChars)
        
        return input.unicodeScalars
            .filter { scalar in
                allowedChars.contains(scalar) &&
                !CharacterSet.controlCharacters.contains(scalar)
            }
            .reduce("") { $0 + String($1) }
    }
    
    private func validatePassword(_ password: String) -> Bool {
        guard !password.isEmpty else { return false }
        guard password.count >= 8 else { return false }
        guard password.count <= 128 else { return false }
        
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        
        return hasLetter && hasNumber
    }
    
    private func changePassword() {
        guard isCurrentPasswordValid && isNewPasswordValid && isConfirmPasswordValid else {
            errorMessage = "Please enter valid passwords"
            showError = true
            return
        }
        
        let sanitizedNewPassword = sanitizePassword(newPassword)
        let sanitizedConfirmPassword = sanitizePassword(confirmPassword)
        
        guard sanitizedNewPassword == sanitizedConfirmPassword else {
            errorMessage = "Passwords do not match"
            showError = true
            return
        }
        
        isChanging = true
        
        // Mock password change - simulate API call
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // In production, this would call the backend API to change password
            await MainActor.run {
                isChanging = false
                showSuccess = true
            }
        }
    }
}

