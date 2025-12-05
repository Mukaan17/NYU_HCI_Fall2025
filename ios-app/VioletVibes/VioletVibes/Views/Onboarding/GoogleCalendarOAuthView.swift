//
//  GoogleCalendarOAuthView.swift
//  VioletVibes
//

import SwiftUI
import AuthenticationServices
import UIKit

struct GoogleCalendarOAuthView: View {
    @Environment(UserSession.self) private var session
    @Environment(OnboardingViewModel.self) private var onboardingViewModel
    
    @State private var isConnecting = false
    @State private var errorMessage: String? = nil
    @State private var showError = false
    @State private var authSession: ASWebAuthenticationSession? = nil
    @State private var presentationContextProvider: OAuthPresentationContextProvider? = nil
    
    private let apiService = APIService.shared
    private let storage = StorageService.shared
    
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
            
            // Blur Shapes (matching other onboarding views)
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
                    
                    // Google Icon with glass morphism background
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.glassBackground)
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(Theme.Colors.border, lineWidth: 1)
                            )
                        
                        GoogleIcon()
                            .frame(width: 64, height: 64)
                    }
                    .padding(.bottom, Theme.Spacing.md)
                    
                    // Title
                    VStack(spacing: Theme.Spacing.sm) {
                        Text("Connect Google Calendar")
                            .themeFont(size: .`3xl`, weight: .bold)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("Link your Google Calendar to get personalized recommendations based on your free time.")
                            .themeFont(size: .lg)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.`2xl`)
                    }
                    
                    // Benefits with glass morphism cards
                    VStack(spacing: Theme.Spacing.md) {
                        BenefitCard(icon: "clock.fill", text: "See your free time at a glance")
                        BenefitCard(icon: "sparkles", text: "Get recommendations when you're available")
                        BenefitCard(icon: "calendar", text: "Sync with your Google Suite calendar")
                    }
                    .padding(.horizontal, Theme.Spacing.`2xl`)
                    
                    Spacer()
                        .frame(height: Theme.Spacing.`2xl`)
                    
                    // Connect Button
                    PrimaryButton(
                        title: isConnecting ? "Connecting..." : "Connect Google Calendar",
                        action: {
                            Task {
                                await connectGoogleCalendar()
                            }
                        },
                        disabled: isConnecting
                    )
                    .overlay(
                        Group {
                            if isConnecting {
                                HStack {
                                    ProgressView()
                                        .tint(Theme.Colors.textPrimary)
                                    Spacer()
                                }
                                .padding(.leading, Theme.Spacing.`2xl`)
                            }
                        }
                    )
                    .padding(.horizontal, Theme.Spacing.`2xl`)
                    .padding(.bottom, Theme.Spacing.lg)
                    
                    // Skip Button
                    Button(action: {
                        // Mark as completed and continue
                        onboardingViewModel.markCalendarOAuthCompleted()
                    }) {
                        Text("Skip for now")
                            .themeFont(size: .base)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .padding(.bottom, Theme.Spacing.`4xl`)
                }
            }
            .scrollIndicators(.hidden)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Failed to connect Google Calendar")
        }
        .onDisappear {
            // Cancel any active authentication session when view disappears
            authSession?.cancel()
            authSession = nil
        }
    }
    
    private func connectGoogleCalendar() async {
        guard let jwt = session.jwt else {
            await MainActor.run {
                errorMessage = "Please log in first"
                showError = true
            }
            return
        }
        
        await MainActor.run {
            isConnecting = true
            errorMessage = nil
        }
        
        do {
            // Get authorization URL from backend
            let authResponse = try await apiService.getGoogleCalendarAuthURL(jwt: jwt)
            
            // Check if already linked
            if authResponse.status == "already_linked" || authResponse.authorization_url == nil {
                // Already linked - mark as complete
                await session.markCalendarLinked(storage)
                await MainActor.run {
                    onboardingViewModel.markCalendarOAuthCompleted()
                    isConnecting = false
                }
                return
            }
            
            // Ensure we have an authorization URL
            guard let authURLString = authResponse.authorization_url,
                  let authURL = URL(string: authURLString) else {
                await MainActor.run {
                    isConnecting = false
                    errorMessage = "Invalid authorization URL"
                    showError = true
                }
                return
            }
            
            // Open OAuth flow using ASWebAuthenticationSession
            // Use ASWebAuthenticationSession to open Google OAuth
            // Google will redirect to backend, backend processes and redirects to iOS app
            let callbackURLScheme = "violetvibes" // URL scheme from Info.plist
            
            await MainActor.run {
                // Create presentation context provider and retain it
                let contextProvider = OAuthPresentationContextProvider()
                presentationContextProvider = contextProvider
                
                // Create and configure the session on the main thread
                let newSession = ASWebAuthenticationSession(
                    url: authURL,
                    callbackURLScheme: callbackURLScheme
                ) { callbackURL, error in
                    Task { @MainActor in
                        if let error = error {
                            // User cancelled or error occurred
                            if let authError = error as? ASWebAuthenticationSessionError,
                               authError.code == .canceledLogin {
                                // User cancelled - that's okay, just reset connecting state
                                isConnecting = false
                                return
                            }
                            isConnecting = false
                            errorMessage = "Failed to connect: \(error.localizedDescription)"
                            showError = true
                            return
                        }
                        
                        guard let callbackURL = callbackURL else {
                            isConnecting = false
                            errorMessage = "Invalid callback URL"
                            showError = true
                            return
                        }
                        
                        // Backend redirects to violetvibes://calendar-oauth?status=success
                        // Check if this is our success callback
                        if callbackURL.scheme == "violetvibes" && callbackURL.host == "calendar-oauth" {
                            let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
                            let status = components?.queryItems?.first(where: { $0.name == "status" })?.value
                            
                            if status == "success" {
                                Task {
                                    await handleOAuthSuccess()
                                }
                            } else {
                                isConnecting = false
                                let errorMsg = components?.queryItems?.first(where: { $0.name == "message" })?.value ?? "OAuth failed"
                                errorMessage = errorMsg
                                showError = true
                            }
                        } else {
                            // Fallback: try to extract code and call backend directly
                            let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
                            let code = components?.queryItems?.first(where: { $0.name == "code" })?.value
                            let state = components?.queryItems?.first(where: { $0.name == "state" })?.value
                            
                            if let code = code, let state = state, let jwt = session.jwt {
                                // Call backend callback endpoint with code and token
                                Task {
                                    await handleOAuthCallback(code: code, state: state, jwt: jwt)
                                }
                            } else {
                                isConnecting = false
                                errorMessage = "Invalid OAuth callback"
                                showError = true
                            }
                        }
                    }
                }
                
                // Configure the session BEFORE storing it
                newSession.presentationContextProvider = contextProvider
                newSession.prefersEphemeralWebBrowserSession = false
                
                // Store the session to prevent deallocation
                authSession = newSession
                
                // Start the OAuth session immediately after configuration
                let started = newSession.start()
                
                if !started {
                    isConnecting = false
                    errorMessage = "Failed to start authentication session. Please ensure the app is in the foreground and try again."
                    showError = true
                    // Clean up
                    authSession = nil
                    presentationContextProvider = nil
                }
            }
            
        } catch {
            await MainActor.run {
                isConnecting = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func handleOAuthCallback(code: String, state: String, jwt: String) async {
        // Build callback URL with code, state, and token
        // Get base URL from environment or config
        let baseURLString: String
        if let envURL = ProcessInfo.processInfo.environment["API_URL"], !envURL.isEmpty {
            baseURLString = envURL
        } else if let configURL = Bundle.main.object(forInfoDictionaryKey: "API_URL") as? String, !configURL.isEmpty {
            baseURLString = configURL
        } else {
            baseURLString = "http://localhost:5001"
        }
        
        guard let callbackURL = URL(string: "\(baseURLString)/api/calendar/oauth/callback?code=\(code)&state=\(state)&token=\(jwt)") else {
            await MainActor.run {
                errorMessage = "Failed to build callback URL"
                showError = true
            }
            return
        }
        
        do {
            var request = URLRequest(url: callbackURL)
            request.httpMethod = "GET"
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw APIError.invalidResponse
            }
            
            await handleOAuthSuccess()
        } catch {
            await MainActor.run {
                errorMessage = "Failed to complete OAuth: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private func handleOAuthSuccess() async {
        // Mark calendar as linked
        await session.markCalendarLinked(storage)
        
        await MainActor.run {
            // Continue onboarding
            onboardingViewModel.markCalendarOAuthCompleted()
        }
    }
}

struct GoogleIcon: View {
    var body: some View {
        ZStack {
            // Google's multi-colored logo - simplified version
            // Blue section (top-right)
            Circle()
                .trim(from: 0.0, to: 0.25)
                .stroke(Color(red: 0.26, green: 0.52, blue: 0.96), lineWidth: 12)
                .rotationEffect(.degrees(-90))
            
            // Green section (bottom-right)
            Circle()
                .trim(from: 0.25, to: 0.5)
                .stroke(Color(red: 0.13, green: 0.59, blue: 0.31), lineWidth: 12)
                .rotationEffect(.degrees(-90))
            
            // Yellow section (bottom-left)
            Circle()
                .trim(from: 0.5, to: 0.75)
                .stroke(Color(red: 0.99, green: 0.75, blue: 0.18), lineWidth: 12)
                .rotationEffect(.degrees(-90))
            
            // Red section (top-left)
            Circle()
                .trim(from: 0.75, to: 1.0)
                .stroke(Color(red: 0.91, green: 0.24, blue: 0.21), lineWidth: 12)
                .rotationEffect(.degrees(-90))
            
            // Center "G" text
            Text("G")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(red: 0.26, green: 0.52, blue: 0.96))
        }
        .frame(width: 64, height: 64)
    }
}

struct BenefitCard: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(Theme.Colors.accentBlue.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Theme.Colors.accentBlue)
            }
            
            Text(text)
                .themeFont(size: .base)
                .foregroundColor(Theme.Colors.textPrimary)
            
            Spacer()
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Colors.glassBackground)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
        .cornerRadius(Theme.BorderRadius.md)
    }
}

// Helper class for ASWebAuthenticationSession
class OAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Try to get the key window from all connected scenes
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                // First try to find the key window
                if let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
                    return keyWindow
                }
                // Fallback to the first window in the scene
                if let firstWindow = windowScene.windows.first {
                    return firstWindow
                }
            }
        }
        
        // Last resort: try to get any window from the app delegate
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            // Create a temporary window if needed (shouldn't happen in normal flow)
            let window = windowScene.windows.first ?? UIWindow(windowScene: windowScene)
            return window
        }
        
        // Absolute last resort: create a new window
        // This should never happen in a properly configured app
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return UIWindow(windowScene: windowScene)
        }
        
        // This should never execute, but required for compilation
        return UIWindow(frame: UIScreen.main.bounds)
    }
}
