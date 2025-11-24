//
//  LoginView.swift
//  VioletVibes
//

import SwiftUI
import AuthenticationServices
import UIKit

struct LoginView: View {
    @Environment(OnboardingViewModel.self) private var onboardingViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoggingIn = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isEmailValid: Bool = false
    @State private var isPasswordValid: Bool = false
    
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
            
            ScrollView {
                VStack(spacing: Theme.Spacing.`4xl`) {
                    Spacer()
                        .frame(height: 60)
                    
                    // App Icon
                    if let appIcon = UIImage(named: "AppIcon") ?? getAppIcon() {
                        Image(uiImage: appIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 26))
                            .shadow(color: Theme.Colors.gradientStart.opacity(0.3), radius: 20, x: 0, y: 10)
                    } else {
                        // Fallback if app icon not found
                        Image(systemName: "app.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Theme.Colors.gradientStart)
                            .frame(width: 120, height: 120)
                    }
                    
                    // Title
                    VStack(spacing: Theme.Spacing.sm) {
                        Text("Welcome Back")
                            .themeFont(size: .`3xl`, weight: .bold)
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Text("Sign in to continue")
                            .themeFont(size: .lg)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Email")
                            .themeFont(size: .sm, weight: .semiBold)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        TextField("Enter your email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .themeFont(size: .base)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .padding(Theme.Spacing.`2xl`)
                            .background(Theme.Colors.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                    .stroke(isEmailValid && !email.isEmpty ? Theme.Colors.gradientStart : Theme.Colors.border, lineWidth: 1)
                            )
                            .cornerRadius(Theme.BorderRadius.md)
                            .onChange(of: email) { oldValue, newValue in
                                let sanitized = sanitizeEmail(newValue)
                                if sanitized != newValue {
                                    email = sanitized
                                }
                                isEmailValid = validateEmail(sanitized)
                            }
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Password")
                            .themeFont(size: .sm, weight: .semiBold)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        SecureField("Enter your password", text: $password)
                            .textContentType(.password)
                            .themeFont(size: .base)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .padding(Theme.Spacing.`2xl`)
                            .background(Theme.Colors.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                    .stroke(isPasswordValid && !password.isEmpty ? Theme.Colors.gradientStart : Theme.Colors.border, lineWidth: 1)
                            )
                            .cornerRadius(Theme.BorderRadius.md)
                            .onChange(of: password) { oldValue, newValue in
                                let sanitized = sanitizePassword(newValue)
                                if sanitized != newValue {
                                    password = sanitized
                                }
                                isPasswordValid = validatePassword(sanitized)
                            }
                    }
                    
                    // Log In Button
                    Button(action: {
                        handleEmailLogin()
                    }) {
                        HStack {
                            if isLoggingIn {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Log In")
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
                    .disabled(isLoggingIn || !isEmailValid || !isPasswordValid)
                    .opacity((isLoggingIn || !isEmailValid || !isPasswordValid) ? 0.5 : 1.0)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Theme.Colors.border)
                            .frame(height: 1)
                        
                        Text("or")
                            .themeFont(size: .sm)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .padding(.horizontal, Theme.Spacing.lg)
                        
                        Rectangle()
                            .fill(Theme.Colors.border)
                            .frame(height: 1)
                    }
                    .padding(.vertical, Theme.Spacing.`2xl`)
                    
                    // Sign in with Apple (Native Button)
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            handleAppleSignIn(result)
                        }
                    )
                    .signInWithAppleButtonStyle(.whiteOutline)
                    .frame(height: 50)
                    .cornerRadius(Theme.BorderRadius.md)
                    .disabled(isLoggingIn)
                    .opacity(isLoggingIn ? 0.5 : 1.0)
                    
                    // Sign in with Google (Mock Native Button)
                    // Following Google Sign-In iOS documentation: https://developers.google.com/identity/sign-in/ios/sign-in#using-swiftui
                    // In production, replace with: GoogleSignInButton(action: handleGoogleSignIn)
                    GoogleSignInButtonMock(action: handleGoogleSignIn)
                        .disabled(isLoggingIn)
                        .opacity(isLoggingIn ? 0.5 : 1.0)
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, Theme.Spacing.`2xl`)
            }
            .scrollIndicators(.hidden)
        }
        .alert("Login Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Validation Functions
    
    /// Sanitizes email input by removing invalid characters
    private func sanitizeEmail(_ input: String) -> String {
        // Only allow: alphanumeric, @, ., -, _, +
        let allowedCharacters = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: "@._+-"))
        
        return input.unicodeScalars
            .filter { allowedCharacters.contains($0) }
            .reduce("") { $0 + String($1) }
    }
    
    /// Validates email format and character restrictions
    private func validateEmail(_ email: String) -> Bool {
        guard !email.isEmpty else { return false }
        
        // Length check
        guard email.count >= 5 && email.count <= 254 else { return false }
        
        // Must contain exactly one @
        let atCount = email.filter { $0 == "@" }.count
        guard atCount == 1 else { return false }
        
        // Split by @
        let components = email.split(separator: "@", maxSplits: 1)
        guard components.count == 2 else { return false }
        
        let localPart = String(components[0])
        let domainPart = String(components[1])
        
        // Local part validation (before @)
        guard !localPart.isEmpty && localPart.count <= 64 else { return false }
        guard localPart.first != "." && localPart.last != "." else { return false }
        guard !localPart.contains("..") else { return false }
        
        // Domain part validation (after @)
        guard !domainPart.isEmpty && domainPart.count <= 253 else { return false }
        guard domainPart.contains(".") else { return false }
        guard domainPart.first != "." && domainPart.last != "." && domainPart.last != "-" else { return false }
        guard !domainPart.contains("..") else { return false }
        
        // Basic email regex pattern
        let emailPattern = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailPattern)
        
        return emailPredicate.evaluate(with: email)
    }
    
    /// Sanitizes password input by removing dangerous characters
    private func sanitizePassword(_ input: String) -> String {
        // Allow printable ASCII characters except dangerous ones: < > ' " \ ` | { } [ ] ; : = & $ # * ? ~
        // This prevents injection attacks while allowing common password characters
        let dangerousChars = CharacterSet(charactersIn: "<>'\"\\`|{}[];:=&$#*?~")
        
        // Build allowed character set: alphanumerics + safe punctuation/symbols, excluding dangerous chars
        var allowedChars = CharacterSet.alphanumerics
        allowedChars.insert(charactersIn: " !@%^()_+-.,/")
        allowedChars.subtract(dangerousChars)
        
        // Filter out control characters and non-printable characters
        return input.unicodeScalars
            .filter { scalar in
                // Check if it's in allowed set and not a control character
                allowedChars.contains(scalar) && 
                !CharacterSet.controlCharacters.contains(scalar)
            }
            .reduce("") { $0 + String($1) }
    }
    
    /// Validates password strength and character restrictions
    private func validatePassword(_ password: String) -> Bool {
        guard !password.isEmpty else { return false }
        
        // Minimum length requirement
        guard password.count >= 8 else { return false }
        
        // Maximum length requirement (prevent DoS)
        guard password.count <= 128 else { return false }
        
        // Check for at least one letter and one number (basic strength requirement)
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        
        return hasLetter && hasNumber
    }
    
    private func handleEmailLogin() {
        // Double-check validation before proceeding
        guard isEmailValid && isPasswordValid else {
            errorMessage = "Please enter valid email and password"
            showError = true
            return
        }
        
        // Sanitize inputs one more time before sending
        let sanitizedEmail = sanitizeEmail(email)
        let sanitizedPassword = sanitizePassword(password)
        
        guard validateEmail(sanitizedEmail) && validatePassword(sanitizedPassword) else {
            errorMessage = "Invalid email or password format"
            showError = true
            return
        }
        
        isLoggingIn = true
        
        // Mock authentication - simulate API call
        Task {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Mock: Accept any credentials
            // In production, this would call the backend API
            await MainActor.run {
                isLoggingIn = false
                onboardingViewModel.markLoggedIn()
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            isLoggingIn = true
            
            // Handle successful authorization
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // In production, send credential to backend
                print("Apple Sign In successful: \(appleIDCredential.user)")
                
                Task {
                    // Simulate network delay
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    
                    await MainActor.run {
                        isLoggingIn = false
                        onboardingViewModel.markLoggedIn()
                    }
                }
            }
        case .failure(let error):
            isLoggingIn = false
            errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
            showError = true
        }
    }
    
    // Helper function to get app icon programmatically
    private func getAppIcon() -> UIImage? {
        // Try to get app icon from bundle
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String] {
            // Try the largest icon first (usually the last one)
            for iconName in iconFiles.reversed() {
                if let image = UIImage(named: iconName) {
                    return image
                }
            }
        }
        
        // Fallback: try common app icon asset names
        let commonNames = ["AppIcon", "AppIconImage", "Icon", "App"]
        for name in commonNames {
            if let image = UIImage(named: name) {
                return image
            }
        }
        
        return nil
    }
    
    private func handleGoogleSignIn() {
        isLoggingIn = true
        
        // Mock Google Sign In - simulate authentication
        Task {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Mock: Success
            // In production, this would integrate with Google Sign In
            await MainActor.run {
                isLoggingIn = false
                onboardingViewModel.markLoggedIn()
            }
        }
    }
}

// MARK: - Google Sign-In Button Mock
// Mock implementation matching GoogleSignInButton from GoogleSignInSwift
// Reference: https://developers.google.com/identity/sign-in/ios/sign-in#using-swiftui
struct GoogleSignInButtonMock: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Google logo - official Google "G" icon
                ZStack {
                    // Google logo background (white square)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                    
                    // Google "G" - using official Google blue color
                    Text("G")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.26, green: 0.52, blue: 0.96)) // Google blue #4285F4
                }
                
                // Button text
                Text("Sign in with Google")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.13, green: 0.13, blue: 0.13)) // Google text color #212121
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50) // Standard button height matching Apple's Sign In button
            .background(Color.white)
            .cornerRadius(Theme.BorderRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                    .stroke(Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 1) // Google border color
            )
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        }
    }
}

