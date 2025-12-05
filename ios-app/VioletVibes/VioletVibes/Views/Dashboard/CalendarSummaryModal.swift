//
//  CalendarSummaryModal.swift
//  VioletVibes
//

import SwiftUI
import AuthenticationServices
import UIKit

struct CalendarSummaryModal: View {
    let events: [CalendarEvent]
    @Binding var isPresented: Bool
    let calendarLinked: Bool
    let onCalendarLinked: (() -> Void)?
    @State private var currentTime = Date()
    @State private var timer: Timer?
    @Environment(UserSession.self) private var session
    @Environment(OnboardingViewModel.self) private var onboardingViewModel
    @State private var showGoogleCalendarOAuth = false
    
    // Filter out events that have ended
    private var activeEvents: [CalendarEvent] {
        let now = currentTime
        return events.filter { event in
            // If event has an end time, check if it's in the future
            if let endString = event.end,
               let endDate = parseDate(endString) {
                return endDate > now
            }
            // If no end time, check start time
            if let startString = event.start,
               let startDate = parseDate(startString) {
                return startDate > now
            }
            // If no dates, include it (shouldn't happen, but safe fallback)
            return true
        }
    }
    
    // Group events by date
    private var groupedEvents: [(String, [CalendarEvent])] {
        let calendar = Calendar.current
        let now = currentTime
        
        let grouped = Dictionary(grouping: activeEvents) { event -> String in
            guard let startString = event.start,
                  let startDate = parseDate(startString) else {
                return "Other"
            }
            
            if calendar.isDateInToday(startDate) {
                return "Today"
            } else if calendar.isDateInTomorrow(startDate) {
                return "Tomorrow"
            } else if startDate > now {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE, MMMM d"
                return formatter.string(from: startDate)
            } else {
                return "Past"
            }
        }
        
        // Sort by date, with Today first, then Tomorrow, then future dates, then Past
        let sortedKeys = grouped.keys.sorted { key1, key2 in
            let order = ["Today", "Tomorrow", "Past", "Other"]
            let index1 = order.firstIndex(of: key1) ?? Int.max
            let index2 = order.firstIndex(of: key2) ?? Int.max
            
            if index1 != Int.max || index2 != Int.max {
                return index1 < index2
            }
            
            // Both are date strings, sort alphabetically
            return key1 < key2
        }
        
        return sortedKeys.compactMap { key in
            guard let events = grouped[key], !events.isEmpty else { return nil }
            // Sort events within each group by start time
            let sortedEvents = events.sorted { event1, event2 in
                guard let start1 = event1.start,
                      let date1 = parseDate(start1),
                      let start2 = event2.start,
                      let date2 = parseDate(start2) else {
                    return false
                }
                return date1 < date2
            }
            return (key, sortedEvents)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                // Show Google Calendar OAuth if calendar is not linked and no system events
                if !calendarLinked && activeEvents.isEmpty {
                    GoogleCalendarOAuthModalContent(
                        onConnectSuccess: {
                            // Refresh calendar status and close modal
                            Task {
                                // Call the callback to reload dashboard
                                onCalendarLinked?()
                                // Close the modal
                                isPresented = false
                            }
                        },
                        onSkip: {
                            isPresented = false
                        }
                    )
                } else if activeEvents.isEmpty {
                    VStack(spacing: Theme.Spacing.lg) {
                        Image(systemName: "calendar")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        Text("No events")
                            .themeFont(size: .xl, weight: .semiBold)
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Text("You're free for the rest of the day!")
                            .themeFont(size: .base)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.Spacing.`2xl`) {
                            ForEach(groupedEvents, id: \.0) { dateGroup, dateEvents in
                                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                                    // Date header
                                    Text(dateGroup)
                                        .themeFont(size: .lg, weight: .bold)
                                        .foregroundColor(Theme.Colors.textPrimary)
                                        .padding(.horizontal, Theme.Spacing.`2xl`)
                                        .padding(.top, dateGroup == groupedEvents.first?.0 ? 0 : Theme.Spacing.xl)
                                    
                                    // Events for this date
                                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                                        ForEach(dateEvents, id: \.id) { event in
                                            CalendarEventRow(event: event)
                                        }
                                    }
                                    .padding(.horizontal, Theme.Spacing.`2xl`)
                                }
                            }
                        }
                        .padding(.vertical, Theme.Spacing.`2xl`)
                    }
                }
            }
            .navigationTitle(calendarLinked || !activeEvents.isEmpty ? "Your Schedule" : "Connect Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(Theme.Colors.textPrimary)
                }
            }
            .onAppear {
                // Start timer to update every minute
                timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
                    currentTime = Date()
                }
            }
            .onDisappear {
                // Stop timer when view disappears
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        let cleaned = dateString.replacingOccurrences(of: "Z", with: "+00:00")
        return formatter.date(from: cleaned)
    }
}

struct CalendarEventRow: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Time indicator with duration
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                if let start = event.start, let startDate = parseDate(start) {
                    Text(formatTime(startDate))
                        .themeFont(size: .sm, weight: .semiBold)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    if let end = event.end, let endDate = parseDate(end) {
                        Text(formatTime(endDate))
                            .themeFont(size: .xs)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        // Show duration
                        let duration = endDate.timeIntervalSince(startDate)
                        let hours = Int(duration / 3600)
                        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
                        
                        if hours > 0 || minutes > 0 {
                            Text(formatDuration(hours: hours, minutes: minutes))
                                .themeFont(size: .xs)
                                .foregroundColor(Theme.Colors.textSecondary.opacity(0.7))
                        }
                    }
                }
            }
            .frame(width: 70, alignment: .leading)
            
            // Event details
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(event.name ?? "Untitled Event")
                    .themeFont(size: .base, weight: .semiBold)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(2)
                
                if let location = event.location, !location.isEmpty {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.textSecondary)
                        Text(location)
                            .themeFont(size: .sm)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .themeFont(size: .sm)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(3)
                }
            }
            
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
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        let cleaned = dateString.replacingOccurrences(of: "Z", with: "+00:00")
        return formatter.date(from: cleaned)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDuration(hours: Int, minutes: Int) -> String {
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

// Simplified Google Calendar OAuth content for modal presentation
struct GoogleCalendarOAuthModalContent: View {
    @Environment(UserSession.self) private var session
    @Environment(OnboardingViewModel.self) private var onboardingViewModel
    
    @State private var isConnecting = false
    @State private var errorMessage: String? = nil
    @State private var showError = false
    @State private var authSession: ASWebAuthenticationSession? = nil
    @State private var presentationContextProvider: OAuthPresentationContextProvider? = nil
    
    let onConnectSuccess: () -> Void
    let onSkip: () -> Void
    
    private let apiService = APIService.shared
    private let storage = StorageService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.`4xl`) {
                Spacer()
                    .frame(height: 40)
                
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
                Button(action: onSkip) {
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
                    isConnecting = false
                    onConnectSuccess()
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
            
            // Use ASWebAuthenticationSession to open Google OAuth
            let callbackURLScheme = "violetvibes"
            
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
            isConnecting = false
            onConnectSuccess()
        }
    }
}
