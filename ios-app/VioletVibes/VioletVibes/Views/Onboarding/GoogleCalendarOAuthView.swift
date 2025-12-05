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
            
            VStack(spacing: Theme.Spacing.`4xl`) {
                Spacer()
                
                // Icon
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 64))
                    .foregroundColor(Theme.Colors.accentBlue)
                    .padding(.bottom, Theme.Spacing.`2xl`)
                
                // Title
                Text("Connect Google Calendar")
                    .themeFont(size: .`3xl`, weight: .bold)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                // Description
                Text("Link your Google Calendar to get personalized recommendations based on your free time.")
                    .themeFont(size: .lg)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.`2xl`)
                
                // Benefits
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    BenefitRow(icon: "clock.fill", text: "See your free time at a glance")
                    BenefitRow(icon: "sparkles", text: "Get recommendations when you're available")
                    BenefitRow(icon: "calendar", text: "Sync with your Google Suite calendar")
                }
                .padding(.horizontal, Theme.Spacing.`2xl`)
                .padding(.top, Theme.Spacing.`2xl`)
                
                Spacer()
                
                // Connect Button
                Button(action: {
                    Task {
                        await connectGoogleCalendar()
                    }
                }) {
                    HStack {
                        if isConnecting {
                            ProgressView()
                                .tint(Theme.Colors.textPrimary)
                        } else {
                            Image(systemName: "calendar.badge.plus")
                            Text("Connect Google Calendar")
                                .themeFont(size: .lg, weight: .semiBold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.lg)
                    .background(Theme.Colors.accentBlue)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .cornerRadius(Theme.BorderRadius.md)
                }
                .disabled(isConnecting)
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
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Failed to connect Google Calendar")
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
            await MainActor.run {
                isConnecting = false
            }
            
            // Use ASWebAuthenticationSession to open Google OAuth
            // Google will redirect to backend, backend processes and redirects to iOS app
            let callbackURLScheme = "violetvibes" // URL scheme from Info.plist
            
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: callbackURLScheme
            ) { callbackURL, error in
                Task { @MainActor in
                    if let error = error {
                        // User cancelled or error occurred
                        if let authError = error as? ASWebAuthenticationSessionError,
                           authError.code == .canceledLogin {
                            // User cancelled - that's okay
                            return
                        }
                        self.errorMessage = "Failed to connect: \(error.localizedDescription)"
                        self.showError = true
                        return
                    }
                    
                    guard let callbackURL = callbackURL else {
                        self.errorMessage = "Invalid callback URL"
                        self.showError = true
                        return
                    }
                    
                    // Backend redirects to violetvibes://calendar-oauth?status=success
                    // Check if this is our success callback
                    if callbackURL.scheme == "violetvibes" && callbackURL.host == "calendar-oauth" {
                        let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
                        let status = components?.queryItems?.first(where: { $0.name == "status" })?.value
                        
                        if status == "success" {
                            Task {
                                await self.handleOAuthSuccess()
                            }
                        } else {
                            let errorMsg = components?.queryItems?.first(where: { $0.name == "message" })?.value ?? "OAuth failed"
                            self.errorMessage = errorMsg
                            self.showError = true
                        }
                    } else {
                        // Fallback: try to extract code and call backend directly
                        let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
                        let code = components?.queryItems?.first(where: { $0.name == "code" })?.value
                        let state = components?.queryItems?.first(where: { $0.name == "state" })?.value
                        
                        if let code = code, let state = state, let jwt = self.session.jwt {
                            // Call backend callback endpoint with code and token
                            Task {
                                await self.handleOAuthCallback(code: code, state: state, jwt: jwt)
                            }
                        } else {
                            self.errorMessage = "Invalid OAuth callback"
                            self.showError = true
                        }
                    }
                }
            }
            
            session.presentationContextProvider = OAuthPresentationContextProvider()
            session.prefersEphemeralWebBrowserSession = false
            
            // Start the OAuth session (synchronous, but callback is async)
            _ = session.start()
            
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

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Theme.Colors.accentBlue)
                .frame(width: 24)
            
            Text(text)
                .themeFont(size: .base)
                .foregroundColor(Theme.Colors.textSecondary)
        }
    }
}

// Helper class for ASWebAuthenticationSession
class OAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Get the key window from the scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return window
        }
        // Fallback: return first window
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window
        }
        // Last resort: create a new window (shouldn't happen)
        return UIWindow(frame: UIScreen.main.bounds)
    }
}
