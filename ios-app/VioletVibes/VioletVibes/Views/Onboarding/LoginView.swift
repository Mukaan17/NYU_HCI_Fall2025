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

    // MARK: - Google Calendar OAuth Launch
    private func openGoogleCalendarOAuth() {
        guard let jwt = session.jwt,
              let url = URL(
                string: "\(APIService.serverURL)/calendar/oauth/google/start?token=\(jwt)"
              ) else {
            errorMessage = "Missing session token"
            showError = true
            return
        }
        UIApplication.shared.open(url)
    }

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

            // Blur shapes
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
                    Spacer().frame(height: 60)

                    // App Icon
                    if let appIcon = UIImage(named: "AppIcon") ?? getAppIcon() {
                        Image(uiImage: appIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 26))
                            .shadow(color: Theme.Colors.gradientStart.opacity(0.3), radius: 20, x: 0, y: 10)
                    }

                    // Tab Selector
                    TabSelectorView(isSignUpMode: $isSignUpMode)
                        .padding(.horizontal, Theme.Spacing.`2xl`)

                    // Titles
                    VStack(spacing: Theme.Spacing.sm) {
                        Text(isSignUpMode ? "Welcome" : "Welcome Back")
                            .themeFont(size: .`3xl`, weight: .bold)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .opacity(welcomeTextOpacity)

                        Text(isSignUpMode ? "Create your account" : "Sign in to continue")
                            .themeFont(size: .lg)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .opacity(welcomeTextOpacity)
                    }

                    // Sign-Up First Name
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
                                .cornerRadius(Theme.BorderRadius.md)
                        }
                    }

                    // Email
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text(isSignUpMode ? "NYU Email" : "Email")
                            .themeFont(size: .sm, weight: .semiBold)

                        TextField(isSignUpMode ? "Enter your NYU email" : "Enter your email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(Theme.Spacing.`2xl`)
                            .background(.ultraThinMaterial)
                            .cornerRadius(Theme.BorderRadius.md)
                            .onChange(of: email) { _, newValue in
                                let sanitized = sanitizeEmail(newValue)
                                if sanitized != newValue { email = sanitized }

                                isEmailValid = isSignUpMode
                                    ? validateNYUEmail(sanitized)
                                    : validateEmail(sanitized)
                            }
                    }

                    // Password
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Password")
                            .themeFont(size: .sm, weight: .semiBold)

                        SecureField("Enter your password", text: $password)
                            .padding(Theme.Spacing.`2xl`)
                            .background(.ultraThinMaterial)
                            .cornerRadius(Theme.BorderRadius.md)
                            .onChange(of: password) { _, newValue in
                                let sanitized = sanitizePassword(newValue)
                                if sanitized != newValue { password = sanitized }
                                isPasswordValid = validatePassword(sanitized)

                                if isSignUpMode {
                                    isConfirmPasswordValid = validatePassword(confirmPassword)
                                        && confirmPassword == sanitized
                                }
                            }
                    }

                    // Confirm Password
                    if isSignUpMode {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Confirm Password")
                                .themeFont(size: .sm, weight: .semiBold)

                            SecureField("Confirm your password", text: $confirmPassword)
                                .padding(Theme.Spacing.`2xl`)
                                .background(.ultraThinMaterial)
                                .cornerRadius(Theme.BorderRadius.md)
                                .onChange(of: confirmPassword) { _, newValue in
                                    let sanitized = sanitizePassword(newValue)
                                    if sanitized != newValue { confirmPassword = sanitized }
                                    isConfirmPasswordValid =
                                        validatePassword(sanitized) && sanitized == password
                                }
                        }
                    }

                    // Sign Up / Log In Button
                    Button(action: {
                        isSignUpMode ? handleSignUp() : handleEmailLogin()
                    }) {
                        HStack {
                            if (isSignUpMode && isSigningUp) || (!isSignUpMode && isLoggingIn) {
                                ProgressView().tint(.white)
                            } else {
                                Text(isSignUpMode ? "Sign Up" : "Log In")
                                    .themeFont(size: .lg, weight: .bold)
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

                    // Divider
                    HStack {
                        Rectangle().fill(Theme.Colors.border).frame(height: 1)
                        Text("or").themeFont(size: .sm).foregroundColor(Theme.Colors.textSecondary)
                        Rectangle().fill(Theme.Colors.border).frame(height: 1)
                    }
                    .padding(.vertical, Theme.Spacing.`2xl`)

                    // Apple Sign-In
                    SignInWithAppleButton(
                        onRequest: { request in request.requestedScopes = [.fullName, .email] },
                        onCompletion: { result in handleAppleSignIn(result) }
                    )
                    .signInWithAppleButtonStyle(.whiteOutline)
                    .frame(height: 50)
                    .cornerRadius(Theme.BorderRadius.md)

                    // 🌟 NEW — Google Calendar OAuth Button
                    Button(action: openGoogleCalendarOAuth) {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Connect Google Calendar")
                                .themeFont(size: .lg, weight: .medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue.opacity(0.35))
                        .cornerRadius(Theme.BorderRadius.md)
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, Theme.Spacing.`2xl`)
            }
            .scrollIndicators(.hidden)
        }
        .alert(isSignUpMode ? "Sign Up Error" : "Login Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorMessage) }
    }

    // MARK: - Validation and Sanitization
    private func sanitizeEmail(_ input: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "@._+-"))
        return input.unicodeScalars.filter { allowed.contains($0) }.map(String.init).joined()
    }

    private func validateEmail(_ email: String) -> Bool {
        let regex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES[c] %@", regex).evaluate(with: email)
    }

    private func validateNYUEmail(_ email: String) -> Bool {
        guard validateEmail(email) else { return false }
        let domains = ["nyu.edu", "stern.nyu.edu", "poly.edu", "nyumc.org"]
        return domains.contains(email.split(separator: "@").last?.lowercased() ?? "")
    }

    private func sanitizePassword(_ input: String) -> String {
        input.filter { $0.isLetter || $0.isNumber || " !@%^()_+-.,/".contains($0) }
    }

    private func validatePassword(_ password: String) -> Bool {
        password.count >= 8 && password.rangeOfCharacter(from: .letters) != nil &&
        password.rangeOfCharacter(from: .decimalDigits) != nil
    }

    // MARK: - Login / Signup Logic
    private func handleEmailLogin() {
        guard isEmailValid && isPasswordValid else {
            errorMessage = "Invalid email or password"
            showError = true
            return
        }

        let sanitizedEmail = sanitizeEmail(email)
        let sanitizedPassword = sanitizePassword(password)

        isLoggingIn = true

        Task {
            do {
                let auth = try await api.login(email: sanitizedEmail, password: sanitizedPassword)

                let account = UserAccount(
                    email: sanitizedEmail,
                    firstName: firstName,
                    hasLoggedIn: true
                )
                await storage.saveUserAccount(account)

                await session.applyAuthResult(
                    token: auth.token,
                    backendPrefs: auth.user.preferences,
                    backendSettings: auth.user.settings,
                    storage: storage
                )

                await MainActor.run {
                    isLoggingIn = false
                    onboardingViewModel.markLoggedIn()
                }
            } catch {
                await MainActor.run {
                    isLoggingIn = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func handleSignUp() {
        guard !firstName.isEmpty else {
            errorMessage = "Please enter your first name"
            showError = true
            return
        }
        guard isEmailValid, isPasswordValid, isConfirmPasswordValid else {
            errorMessage = "Please enter valid information"
            showError = true
            return
        }

        let sanitizedEmail = sanitizeEmail(email)
        let sanitizedPassword = sanitizePassword(password)

        isSigningUp = true

        Task {
            do {
                let auth = try await api.signup(email: sanitizedEmail, password: sanitizedPassword)

                let account = UserAccount(
                    email: sanitizedEmail,
                    firstName: firstName,
                    hasLoggedIn: true
                )
                await storage.saveUserAccount(account)

                await session.applyAuthResult(
                    token: auth.token,
                    backendPrefs: auth.user.preferences,
                    backendSettings: auth.user.settings,
                    storage: storage
                )

                await MainActor.run {
                    isSigningUp = false
                    onboardingViewModel.markLoggedIn()
                }
            } catch {
                await MainActor.run {
                    isSigningUp = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    // MARK: - Apple Sign-In
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(_):
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                onboardingViewModel.markLoggedIn()
            }
        case .failure(let error):
            errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
            showError = true
        }
    }

    // MARK: - App Icon Fallback
    private func getAppIcon() -> UIImage? {
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String] {
            for name in files.reversed() {
                if let img = UIImage(named: name) { return img }
            }
        }
        return nil
    }
}
