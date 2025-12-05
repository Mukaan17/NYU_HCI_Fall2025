//
//  LoginView.swift
//  VioletVibes
//

import SwiftUI
import AuthenticationServices
import UIKit

struct LoginView: View {
    @Environment(OnboardingViewModel.self) private var onboardingViewModel
    @Environment(UserSession.self) private var session
    @State private var isSignUpMode: Bool = false
    @State private var email: String = ""
    @State private var firstName: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoggingIn = false
    @State private var isSigningUp = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isEmailValid: Bool = false
    @State private var isPasswordValid: Bool = false
    @State private var isConfirmPasswordValid: Bool = false
    @State private var welcomeTextOpacity: Double = 0
    @State private var hasCheckedDefaultMode = false
    
    private let storage = StorageService.shared
    private let api = APIService.shared
    
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
                    
                    // Tab Selector
                    TabSelectorView(isSignUpMode: $isSignUpMode)
                        .padding(.horizontal, Theme.Spacing.`2xl`)
                    
                    // Animated Welcome Text
                    VStack(spacing: Theme.Spacing.sm) {
                        Text(isSignUpMode ? "Welcome" : "Welcome Back")
                            .themeFont(size: .`3xl`, weight: .bold)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .opacity(welcomeTextOpacity)
                            .animation(.smooth(duration: 0.5), value: welcomeTextOpacity)
                            .animation(.smooth(duration: 0.3), value: isSignUpMode)
                        
                        Text(isSignUpMode ? "Create your account" : "Sign in to continue")
                            .themeFont(size: .lg)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .opacity(welcomeTextOpacity)
                            .animation(.smooth(duration: 0.5).delay(0.1), value: welcomeTextOpacity)
                            .animation(.smooth(duration: 0.3), value: isSignUpMode)
                    }
                    
                    // First Name Field (Sign Up Only)
                    if isSignUpMode {
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
                                        .stroke(!firstName.isEmpty ? Theme.Colors.gradientStart.opacity(0.3) : Theme.Colors.border, lineWidth: 1)
                                )
                                .cornerRadius(Theme.BorderRadius.md)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text(isSignUpMode ? "NYU Email" : "Email")
                            .themeFont(size: .sm, weight: .semiBold)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        TextField(isSignUpMode ? "Enter your NYU email" : "Enter your email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .themeFont(size: .base)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .padding(Theme.Spacing.`2xl`)
                            .background(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                    .stroke(isEmailValid && !email.isEmpty ? Theme.Colors.gradientStart.opacity(0.3) : Theme.Colors.border, lineWidth: 1)
                            )
                            .cornerRadius(Theme.BorderRadius.md)
                            .onChange(of: email) { oldValue, newValue in
                                let sanitized = sanitizeEmail(newValue)
                                if sanitized != newValue {
                                    email = sanitized
                                }
                                if isSignUpMode {
                                    isEmailValid = validateNYUEmail(sanitized)
                                } else {
                                    isEmailValid = validateEmail(sanitized)
                                }
                            }
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Password")
                            .themeFont(size: .sm, weight: .semiBold)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        SecureField("Enter your password", text: $password)
                            .textContentType(isSignUpMode ? .newPassword : .password)
                            .themeFont(size: .base)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .padding(Theme.Spacing.`2xl`)
                            .background(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                    .stroke(isPasswordValid && !password.isEmpty ? Theme.Colors.gradientStart.opacity(0.3) : Theme.Colors.border, lineWidth: 1)
                            )
                            .cornerRadius(Theme.BorderRadius.md)
                            .onChange(of: password) { oldValue, newValue in
                                let sanitized = sanitizePassword(newValue)
                                if sanitized != newValue {
                                    password = sanitized
                                }
                                isPasswordValid = validatePassword(sanitized)
                                if isSignUpMode {
                                    isConfirmPasswordValid = validatePassword(confirmPassword) && sanitized == confirmPassword
                                }
                            }
                    }
                    
                    // Confirm Password Field (Sign Up Only)
                    if isSignUpMode {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Confirm Password")
                                .themeFont(size: .sm, weight: .semiBold)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            SecureField("Confirm your password", text: $confirmPassword)
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
                                    isConfirmPasswordValid = validatePassword(sanitized) && sanitized == password
                                }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Action Button
                    Button(action: {
                        if isSignUpMode {
                            handleSignUp()
                        } else {
                            handleEmailLogin()
                        }
                    }) {
                        HStack {
                            if (isSignUpMode && isSigningUp) || (!isSignUpMode && isLoggingIn) {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isSignUpMode ? "Sign Up" : "Log In")
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
                    .disabled(
                        (isSignUpMode && (isSigningUp || !isEmailValid || !isPasswordValid || !isConfirmPasswordValid || firstName.isEmpty)) ||
                        (!isSignUpMode && (isLoggingIn || !isEmailValid || !isPasswordValid))
                    )
                    .opacity(
                        (isSignUpMode && (isSigningUp || !isEmailValid || !isPasswordValid || !isConfirmPasswordValid || firstName.isEmpty)) ||
                        (!isSignUpMode && (isLoggingIn || !isEmailValid || !isPasswordValid))
                        ? 0.5 : 1.0
                    )
                    
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
                    .disabled(isLoggingIn || isSigningUp)
                    .opacity((isLoggingIn || isSigningUp) ? 0.5 : 1.0)
                    
                    // Sign in with Google (Mock Native Button)
                    // Following Google Sign-In iOS documentation: https://developers.google.com/identity/sign-in/ios/sign-in#using-swiftui
                    // In production, replace with: GoogleSignInButton(action: handleGoogleSignIn)
                    GoogleSignInButtonMock(action: handleGoogleSignIn)
                        .disabled(isLoggingIn || isSigningUp)
                        .opacity((isLoggingIn || isSigningUp) ? 0.5 : 1.0)
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, Theme.Spacing.`2xl`)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Dismiss keyboard when tapping outside text fields
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .alert(isSignUpMode ? "Sign Up Error" : "Login Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            // Set smart default based on hasLoggedIn
            if !hasCheckedDefaultMode {
                let hasLoggedIn = await storage.hasLoggedIn
                await MainActor.run {
                    isSignUpMode = !hasLoggedIn
                    hasCheckedDefaultMode = true
                    welcomeTextOpacity = 1.0
                }
            }
        }
        .onChange(of: isSignUpMode) { oldValue, newValue in
            // Animate welcome text when switching modes
            withAnimation(.smooth(duration: 0.3)) {
                welcomeTextOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.smooth(duration: 0.3)) {
                    welcomeTextOpacity = 1.0
                }
            }
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
    
    /// Validates NYU email format
    private func validateNYUEmail(_ email: String) -> Bool {
        // First validate as regular email
        guard validateEmail(email) else { return false }
        
        // Check if it's an NYU domain
        let nyuDomains = ["nyu.edu", "stern.nyu.edu", "poly.edu", "nyumc.org"]
        let domain = email.lowercased().split(separator: "@").last.map(String.init) ?? ""
        
        return nyuDomains.contains { domain == $0 || domain.hasSuffix("." + $0) }
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
        
        Task {
            do {
                // Call real API
                let authResponse = try await api.login(email: sanitizedEmail, password: sanitizedPassword)
                
                // Apply auth result to session
                await session.applyAuthResult(
                    token: authResponse.token,
                    backendPrefs: authResponse.user.preferences,
                    backendSettings: authResponse.user.settings,
                    storage: storage
                )
                
                // Save user data from backend response (includes first_name and home_address)
                // This ensures we have the latest data from database
                var userAccount = UserAccount(
                    email: authResponse.user.email,
                    firstName: authResponse.user.first_name ?? "User",
                    hasLoggedIn: true
                )
                await storage.saveUserAccount(userAccount)
                
                // Save home address from backend if available (encrypted, now decrypted)
                if let homeAddress = authResponse.user.home_address, !homeAddress.isEmpty {
                    await storage.setHomeAddress(homeAddress)
                }
                
                // Check if user has completed onboarding survey
                // If preferences exist and have meaningful data, assume onboarding is complete
                if let prefs = authResponse.user.preferences {
                    // Check if preferences have meaningful data (not just defaults)
                    // This indicates the user has completed the onboarding survey
                    let hasMeaningfulPrefs = (prefs.preferred_vibes != nil && !(prefs.preferred_vibes?.isEmpty ?? true)) ||
                                            (prefs.dietary_restrictions != nil && !(prefs.dietary_restrictions?.isEmpty ?? true)) ||
                                            prefs.max_walk_minutes_default != nil ||
                                            (prefs.interests != nil && !(prefs.interests?.isEmpty ?? true))
                    await storage.setHasCompletedOnboardingSurvey(hasMeaningfulPrefs)
                } else {
                    // No preferences means onboarding not completed
                    await storage.setHasCompletedOnboardingSurvey(false)
                }
                
                await storage.setHasLoggedIn(true)
                
                // Fetch latest profile data from backend to ensure we have current data
                if let jwt = session.jwt {
                    do {
                        let profile = try await api.fetchUserProfile(jwt: jwt)
                        // Update user account with latest first_name if different
                        if let firstName = profile.first_name, firstName != userAccount.firstName {
                            userAccount = UserAccount(
                                email: userAccount.email,
                                firstName: firstName,
                                hasLoggedIn: true
                            )
                            await storage.saveUserAccount(userAccount)
                        }
                        // Update home address if different
                        let currentAddress = await storage.homeAddress
                        if let homeAddress = profile.home_address, homeAddress != currentAddress {
                            await storage.setHomeAddress(homeAddress)
                        }
                    } catch {
                        print("Failed to fetch user profile: \(error)")
                        // Continue with data from login response
                    }
                }
                
                await MainActor.run {
                    isLoggingIn = false
                    onboardingViewModel.markLoggedIn()
                    // Refresh onboarding status to reflect backend data
                    Task {
                        await onboardingViewModel.checkOnboardingStatus()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoggingIn = false
                    if let apiError = error as? APIError {
                        errorMessage = apiError.errorDescription ?? "Login failed. Please try again."
                    } else {
                        errorMessage = "Login failed: \(error.localizedDescription)"
                    }
                    showError = true
                }
            }
        }
    }
    
    private func handleSignUp() {
        // Validate all fields
        guard !firstName.isEmpty else {
            errorMessage = "Please enter your first name"
            showError = true
            return
        }
        
        guard isEmailValid && isPasswordValid && isConfirmPasswordValid else {
            errorMessage = "Please enter valid information"
            showError = true
            return
        }
        
        // Sanitize inputs
        let sanitizedEmail = sanitizeEmail(email)
        let sanitizedPassword = sanitizePassword(password)
        let sanitizedConfirmPassword = sanitizePassword(confirmPassword)
        
        guard validateNYUEmail(sanitizedEmail) && validatePassword(sanitizedPassword) else {
            errorMessage = "Invalid NYU email or password format"
            showError = true
            return
        }
        
        guard sanitizedPassword == sanitizedConfirmPassword else {
            errorMessage = "Passwords do not match"
            showError = true
            return
        }
        
        isSigningUp = true
        
        Task {
            do {
                // Call real API with first name
                let authResponse = try await api.signup(
                    email: sanitizedEmail,
                    password: sanitizedPassword,
                    firstName: firstName.isEmpty ? nil : firstName.trimmingCharacters(in: .whitespaces)
                )
                
                // Apply auth result to session
                await session.applyAuthResult(
                    token: authResponse.token,
                    backendPrefs: authResponse.user.preferences,
                    backendSettings: authResponse.user.settings,
                    storage: storage
                )
                
                // Save user data from backend response (includes first_name and home_address)
                // This ensures we have the latest data from database
                var userAccount = UserAccount(
                    email: authResponse.user.email,
                    firstName: authResponse.user.first_name ?? firstName.trimmingCharacters(in: .whitespaces),
                    hasLoggedIn: true
                )
                await storage.saveUserAccount(userAccount)
                
                // Save home address from backend if available (encrypted, now decrypted)
                if let homeAddress = authResponse.user.home_address, !homeAddress.isEmpty {
                    await storage.setHomeAddress(homeAddress)
                }
                
                // New users haven't completed onboarding survey yet
                // (They'll complete it after signup)
                await storage.setHasCompletedOnboardingSurvey(false)
                
                await storage.setHasLoggedIn(true)
                
                await MainActor.run {
                    isSigningUp = false
                    onboardingViewModel.markLoggedIn()
                    // Refresh onboarding status
                    Task {
                        await onboardingViewModel.checkOnboardingStatus()
                    }
                }
            } catch {
                await MainActor.run {
                    isSigningUp = false
                    if let apiError = error as? APIError {
                        errorMessage = apiError.errorDescription ?? "Sign up failed. Please try again."
                    } else {
                        errorMessage = "Sign up failed: \(error.localizedDescription)"
                    }
                    showError = true
                }
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

// MARK: - Tab Selector View
struct TabSelectorView: View {
    @Binding var isSignUpMode: Bool
    
    var body: some View {
        ZStack {
            // Background
            ZStack {
                // Liquid glass background
                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                    .fill(.thinMaterial)
                
                // Gradient tint overlay
                LinearGradient(
                    colors: [
                        Theme.Colors.gradientStart.opacity(0.15),
                        Theme.Colors.gradientEnd.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(Theme.BorderRadius.md)
            }
            
            // Animated selection indicator (behind text)
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: Theme.BorderRadius.md - 2)
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.gradientStart, Theme.Colors.gradientEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width / 2)
                    .offset(x: isSignUpMode ? geometry.size.width / 2 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSignUpMode)
            }
            .padding(2)
            
            // Tab buttons (on top)
            HStack(spacing: 0) {
                // Login Tab
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isSignUpMode = false
                    }
                }) {
                    Text("Log In")
                        .themeFont(size: .lg, weight: .semiBold)
                        .foregroundColor(isSignUpMode ? Theme.Colors.textSecondary : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.lg)
                }
                
                // Sign Up Tab
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isSignUpMode = true
                    }
                }) {
                    Text("Sign Up")
                        .themeFont(size: .lg, weight: .semiBold)
                        .foregroundColor(isSignUpMode ? .white : Theme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.lg)
                }
            }
        }
        .cornerRadius(Theme.BorderRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
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

