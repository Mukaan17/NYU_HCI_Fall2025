//
//  ChatView.swift
//  VioletVibes
//

import SwiftUI
import CoreLocation
import Foundation

struct ChatView: View {
    @Environment(ChatViewModel.self) private var chatViewModel
    @Environment(PlaceViewModel.self) private var placeViewModel
    @Environment(LocationManager.self) private var locationManager
    @Environment(WeatherManager.self) private var weatherManager
    @Environment(UserSession.self) private var session
    @Environment(TabCoordinator.self) private var tabCoordinator
    
    @FocusState private var isInputFocused: Bool
    @State private var calendarViewModel = CalendarViewModel()
    @State private var dashboardViewModel = DashboardViewModel()
    @State private var isWeatherExpanded = false
    @State private var showCalendarSummary = false
    @State private var selectedVibe: VibeOption? = availableVibes.first
    @State private var isVibePickerExpanded = false
    @State private var vibeButtonFrame: CGRect = .zero
    @State private var weatherButtonFrame: CGRect = .zero
    
    private var backgroundGradient: some View {
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
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerSection
            messagesSection
            inputSection
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.`2xl`) {
            HStack(spacing: Theme.Spacing.lg) {
                weatherBadge
                scheduleBadge
                vibeBadge
            }
            .frame(maxWidth: .infinity)
            .onPreferenceChange(VibeButtonFrameKey.self) { frame in
                vibeButtonFrame = frame
            }
            .onPreferenceChange(WeatherButtonFrameKey.self) { frame in
                weatherButtonFrame = frame
            }
        }
        .padding(.top, Theme.Spacing.`2xl`)
        .padding(.bottom, Theme.Spacing.`2xl`)
        .padding(.horizontal, Theme.Spacing.`2xl`)
        .background(headerBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Theme.Colors.borderLight),
            alignment: .bottom
        )
    }
    
    private var weatherBadge: some View {
        Group {
            if let weather = weatherManager.weather {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isWeatherExpanded.toggle()
                    }
                    // Load forecast if not already loaded (in background, don't wait)
                    if weatherManager.forecast == nil {
                        Task {
                            await weatherManager.loadForecast(locationManager: locationManager)
                        }
                    }
                }) {
                    Text("\(weather.emoji) \(formatTemperature(weather.temp))°F")
                        .themeFont(size: .base, weight: .semiBold)
                        .foregroundColor(Theme.Colors.textBlue)
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.vertical, Theme.Spacing.sm)
                        .frame(minHeight: 40) // Fixed minimum height
                        .background(Theme.Colors.accentBlue)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.BorderRadius.full)
                                .stroke(Theme.Colors.accentBlueMedium, lineWidth: 1)
                        )
                        .cornerRadius(Theme.BorderRadius.full)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: WeatherButtonFrameKey.self, value: geometry.frame(in: .global))
                    }
                )
            } else {
                // Loading state
                HStack(spacing: Theme.Spacing.xs) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Theme.Colors.textBlue)
                    Text("Loading...")
                        .themeFont(size: .base, weight: .semiBold)
                        .foregroundColor(Theme.Colors.textBlue)
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.sm)
                .frame(minHeight: 40) // Fixed minimum height
                .background(Theme.Colors.accentBlue)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.BorderRadius.full)
                        .stroke(Theme.Colors.accentBlueMedium, lineWidth: 1)
                )
                .cornerRadius(Theme.BorderRadius.full)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: weatherManager.weather != nil)
        .onPreferenceChange(WeatherButtonFrameKey.self) { frame in
            weatherButtonFrame = frame
        }
    }
    
    private var scheduleBadge: some View {
        Button(action: {
            // Always show calendar summary modal (shows system calendar events)
            showCalendarSummary = true
        }) {
            Group {
                if calendarViewModel.isLoading {
                    // Loading state
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Theme.Colors.textPrimary)
                } else if let systemFreeTime = calendarViewModel.timeUntilFormatted(), !calendarViewModel.events.isEmpty {
                    // System calendar has data
                    Text(systemFreeTime)
                        .themeFont(size: .base, weight: .semiBold)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                } else if !calendarViewModel.events.isEmpty {
                    // System calendar has events but no upcoming free time (all events are past or ongoing)
                    Text("Free all day")
                        .themeFont(size: .base, weight: .semiBold)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(1)
                } else {
                    // No events - free all day
                    Text("Free all day")
                        .themeFont(size: .base, weight: .semiBold)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, Theme.Spacing.`2xl`)
            .padding(.vertical, Theme.Spacing.md)
            .frame(minHeight: 44) // Increased minimum height for better spacing
            .background(Theme.Colors.glassBackground)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.BorderRadius.full)
                    .stroke(
                        // Use full opacity if we have calendar data (system or Google), reduced if not linked
                        (calendarViewModel.events.isEmpty && !dashboardViewModel.calendarLinked) ? Theme.Colors.border.opacity(0.5) : Theme.Colors.border,
                        lineWidth: 1
                    )
            )
            .cornerRadius(Theme.BorderRadius.full)
        }
        .buttonStyle(.plain)
    }
    
    private var vibeBadge: some View {
        VibePickerDropdown(selectedVibe: $selectedVibe, isExpanded: $isVibePickerExpanded)
    }
    
    private var headerBackground: some View {
        LinearGradient(
            colors: [
                Theme.Colors.accentPurple,
                Theme.Colors.accentBlue,
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .opacity(0.4)
    }
    
    private var messagesSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.xl) {
                    ForEach(chatViewModel.messages) { message in
                        messageView(for: message)
                    }
                    
                    if chatViewModel.isTyping {
                        typingIndicator
                    }
                }
                .padding(.top, Theme.Spacing.`3xl`)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { _ in
                        isInputFocused = false
                    }
            )
            .onChange(of: chatViewModel.messages.count) { oldValue, newValue in
                if newValue > oldValue, let lastMessage = chatViewModel.messages.last {
                    withAnimation(.spring(response: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func messageView(for message: ChatMessage) -> some View {
        if message.type == .recommendations, let recommendations = message.recommendations {
            VStack(spacing: Theme.Spacing.`2xl`) {
                ForEach(recommendations) { recommendation in
                    RecommendationCard(recommendation: recommendation) {
                        let place = SelectedPlace(
                            name: recommendation.title,
                            latitude: recommendation.lat ?? 40.693393,
                            longitude: recommendation.lng ?? -73.98555,
                            walkTime: recommendation.walkTime,
                            distance: recommendation.distance,
                            address: recommendation.description,
                            image: recommendation.image
                        )
                        placeViewModel.setSelectedPlace(place)
                        tabCoordinator.selectedTab = .map
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.`2xl`)
            .padding(.top, Theme.Spacing.`2xl`)
        } else if let content = message.content {
            MessageBubble(message: message, content: content)
                .padding(.horizontal, Theme.Spacing.`2xl`)
        }
    }
    
    private var typingIndicator: some View {
        MessageBubble(
            message: ChatMessage(
                id: 999,
                type: .text,
                role: .ai,
                content: "Violet is thinking…",
                timestamp: Date()
            ),
            content: "Violet is thinking…"
        )
        .padding(.horizontal, Theme.Spacing.`2xl`)
    }
    
    private var inputSection: some View {
        InputField(placeholder: "Ask VioletVibes...", isFocused: $isInputFocused) { text in
            Task {
                await chatViewModel.sendMessage(
                    text,
                    latitude: locationManager.location?.coordinate.latitude,
                    longitude: locationManager.location?.coordinate.longitude,
                    jwt: session.jwt,
                    preferences: session.preferences
                )
            }
        }
        .padding(.horizontal, Theme.Spacing.`2xl`)
        .padding(.bottom, Theme.Spacing.`2xl`)
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
                .onTapGesture {
                    // Dismiss keyboard when tapping background
                    isInputFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            // Vibe picker overlay - positioned at top level to appear above everything
            VibePickerOverlay(
                selectedVibe: $selectedVibe,
                isExpanded: $isVibePickerExpanded,
                buttonFrame: vibeButtonFrame
            )
            .allowsHitTesting(isVibePickerExpanded)
            .zIndex(10000) // Very high z-index to appear above everything
            
            // Weather dropdown overlay - positioned at top level to appear above everything
            WeatherDropdownOverlay(
                currentWeather: weatherManager.weather,
                forecast: weatherManager.forecast,
                isExpanded: $isWeatherExpanded,
                buttonFrame: weatherButtonFrame
            )
            .allowsHitTesting(isWeatherExpanded)
            .zIndex(10000) // Very high z-index to appear above everything
            
            mainContent
        }
        .onAppear {
            // Close any open overlays when view appears
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isWeatherExpanded = false
                isVibePickerExpanded = false
            }
        }
        .task {
            // Load weather on task start (app launch/restart)
            await weatherManager.loadWeather(locationManager: locationManager)
            
            // Load calendar events from system calendar
            await calendarViewModel.loadTodayEvents()
            
            // Load dashboard data (includes Google Calendar) if user is authenticated
            if let jwt = session.jwt {
                await dashboardViewModel.loadDashboard(jwt: jwt)
            }
        }
        .onChange(of: locationManager.location) { oldValue, newValue in
            // Reload weather when location changes
            if newValue != nil {
                Task {
                    await weatherManager.loadWeather(locationManager: locationManager)
                }
            }
        }
        .sheet(isPresented: $showCalendarSummary) {
            // Calendar summary modal shows system calendar events (priority source)
            CalendarSummaryModal(
                events: calendarViewModel.events,
                isPresented: $showCalendarSummary
            )
        }
    }
    
    // Helper function to format temperature (handles negative temperatures correctly)
    private func formatTemperature(_ temp: Int) -> String {
        // Int already handles negative values correctly, just convert to string
        return String(temp)
    }
    
    // Helper function to format free time block
    private func formatFreeTimeBlock(_ block: FreeTimeBlock) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let startDate = formatter.date(from: block.start),
              let endDate = formatter.date(from: block.end) else {
            return "Free time available"
        }

        let now = Date()
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "h:mm a"

        if startDate <= now && endDate > now {
            let endTime = timeFormatter.string(from: endDate)
            return "Free until \(endTime)"
        } else if startDate > now {
            let startTime = timeFormatter.string(from: startDate)
            let endTime = timeFormatter.string(from: endDate)
            return "Free \(startTime)-\(endTime)"
        } else {
            return "Free time available"
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let content: String
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: Theme.Spacing.xs) {
                // Format and display text with proper markdown support
                formattedText(content)
                    .themeFont(size: .lg)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text(formatTime(message.timestamp))
                    .themeFont(size: .xs)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .opacity(0.6)
            }
            .padding(.horizontal, Theme.Spacing.`3xl`)
            .padding(.vertical, Theme.Spacing.`2xl`)
            .background(
                Group {
                    if message.role == .user {
                        LinearGradient(
                            colors: [Theme.Colors.gradientStart, Theme.Colors.gradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color(hex: "31374D")
                    }
                }
            )
            .cornerRadius(Theme.BorderRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.BorderRadius.lg)
                    .stroke(Theme.Colors.border, lineWidth: message.role == .user ? 0 : 1)
            )
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .ai {
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        let minutes = Int(diff / 60)
        
        if minutes < 1 {
            return "Just now"
        } else if minutes < 60 {
            return "\(minutes)m ago"
        } else {
            let hours = minutes / 60
            if hours < 24 {
                return "\(hours)h ago"
            } else {
                return date.formatted(date: .abbreviated, time: .omitted)
            }
        }
    }
    
    // Format text with markdown support and proper spacing
    @ViewBuilder
    private func formattedText(_ text: String) -> some View {
        let cleanedText = cleanAndFormatText(text)
        
        if #available(iOS 15.0, *) {
            // Try to parse as markdown with whitespace preservation
            if let attributedString = try? AttributedString(
                markdown: cleanedText,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            ) {
                // Add paragraph spacing to the attributed string
                let styledString = applyParagraphSpacing(to: attributedString)
                Text(styledString)
            } else {
                // Fallback: display cleaned text with line spacing
                Text(cleanedText)
                    .lineSpacing(6)
            }
        } else {
            Text(cleanedText)
                .lineSpacing(6)
        }
    }
    
    // Apply paragraph spacing to an AttributedString
    @available(iOS 15.0, *)
    private func applyParagraphSpacing(to attributedString: AttributedString) -> AttributedString {
        var styledString = attributedString
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 12
        paragraphStyle.paragraphSpacingBefore = 8
        paragraphStyle.lineSpacing = 6  // Changed from 4 to 6
        
        // Apply paragraph style to entire string
        let paragraphStyleAttribute = AttributeContainer([.paragraphStyle: paragraphStyle])
        styledString.mergeAttributes(paragraphStyleAttribute, mergePolicy: .keepNew)
        
        return styledString
    }
    
    // Decode HTML entities to proper characters
    private func decodeHTMLEntities(_ text: String) -> String {
        var decoded = text
        
        // Named entities
        let entities: [String: String] = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'",
            "&nbsp;": " ",
            "&mdash;": "—",
            "&ndash;": "–",
            "&rsquo;": "'",
            "&lsquo;": "'",
            "&rdquo;": "\"",
            "&ldquo;": "\"",
            "&hellip;": "…",
            "&copy;": "©",
            "&reg;": "®",
            "&trade;": "™"
        ]
        
        // Replace named entities
        for (entity, replacement) in entities {
            decoded = decoded.replacingOccurrences(of: entity, with: replacement)
        }
        
        // Handle numeric entities like &#39; or &#8212;
        // Pattern: &# followed by digits and semicolon
        let numericPattern = #"&#(\d+);"#
        if let regex = try? NSRegularExpression(pattern: numericPattern, options: []) {
            let nsString = decoded as NSString
            let matches = regex.matches(in: decoded, options: [], range: NSRange(location: 0, length: nsString.length))
            
            // Process matches in reverse to maintain correct indices
            for match in matches.reversed() {
                if match.numberOfRanges >= 2 {
                    let numberRange = match.range(at: 1)
                    if let numberString = nsString.substring(with: numberRange) as String?,
                       let number = Int(numberString),
                       let unicodeScalar = UnicodeScalar(number) {
                        let replacement = String(Character(unicodeScalar))
                        let fullRange = match.range
                        decoded = (decoded as NSString).replacingCharacters(in: fullRange, with: replacement)
                    }
                }
            }
        }
        
        return decoded
    }
    
    // Clean and format text for better readability
    private func cleanAndFormatText(_ text: String) -> String {
        // Step 1: Decode HTML entities first
        var cleaned = decodeHTMLEntities(text)
        
        // Step 2: Normalize line endings (convert \r\n and \r to \n)
        cleaned = cleaned.replacingOccurrences(of: "\r\n", with: "\n")
        cleaned = cleaned.replacingOccurrences(of: "\r", with: "\n")
        
        // Step 3: Process line by line to handle formatting properly
        let lines = cleaned.components(separatedBy: "\n")
        var formattedLines: [String] = []
        
        for line in lines {
            var processedLine = line
            
            // Replace multiple spaces/tabs with single space
            processedLine = processedLine.replacingOccurrences(of: "[ \t]+", with: " ", options: String.CompareOptions.regularExpression)
            
            // Trim trailing whitespace but preserve leading whitespace for indentation
            processedLine = processedLine.trimmingCharacters(in: .whitespaces)
            
            if processedLine.isEmpty {
                // Preserve empty lines (they represent paragraph breaks)
                formattedLines.append("")
                continue
            }
            
            // Check if this is a list item - must start with * or - followed by space
            // But NOT if it's part of markdown formatting (**bold** or *italic*)
            let trimmed = processedLine.trimmingCharacters(in: .whitespaces)
            
            // Convert list markers to bullet points
            // Only if it starts with "* " or "- " and is not markdown formatting
            if trimmed.hasPrefix("* ") {
                // Check if it's not part of **bold** formatting
                // If it starts with "**", it's bold, not a list
                if !trimmed.hasPrefix("**") {
                    let afterMarker = String(trimmed.dropFirst(2))
                    processedLine = "• " + afterMarker
                }
            } else if trimmed.hasPrefix("- ") {
                processedLine = "• " + String(trimmed.dropFirst(2))
            }
            
            formattedLines.append(processedLine)
        }
        
        // Step 4: Join lines back together
        cleaned = formattedLines.joined(separator: "\n")
        
        // Step 5: Clean up excessive newlines (3+ consecutive newlines → 2)
        cleaned = cleaned.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: String.CompareOptions.regularExpression)
        
        // Step 6: Trim leading/trailing whitespace but preserve structure
        cleaned = cleaned.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        // Ensure proper spacing around em dashes
        cleaned = cleaned.replacingOccurrences(of: "([^ ])—", with: "$1 — ", options: String.CompareOptions.regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "—([^ ])", with: " — $1", options: String.CompareOptions.regularExpression)
        
        // Add paragraph breaks after sentences ending with ! or ? followed by capital letters
        cleaned = cleaned.replacingOccurrences(of: "([!?])\\s+([A-Z])", with: "$1\n\n$2", options: String.CompareOptions.regularExpression)
        
        // Add paragraph breaks after periods followed by capital letters (new sentences)
        cleaned = cleaned.replacingOccurrences(of: "\\.\\s+([A-Z][a-z]{2,})", with: ".\n\n$1", options: String.CompareOptions.regularExpression)
        
        // Add line breaks before list items (bullet points) if they're on the same line
        cleaned = cleaned.replacingOccurrences(of: "([^\n])(• )", with: "$1\n\n$2", options: String.CompareOptions.regularExpression)
        
        // Add line breaks after colons if followed by a list
        cleaned = cleaned.replacingOccurrences(of: ":([^\n])(• )", with: ":\n\n$1$2", options: String.CompareOptions.regularExpression)
        
        // Clean up multiple newlines (max 2 consecutive for paragraph breaks)
        cleaned = cleaned.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: String.CompareOptions.regularExpression)
        
        // Trim whitespace
        cleaned = cleaned.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        return cleaned
    }
}

