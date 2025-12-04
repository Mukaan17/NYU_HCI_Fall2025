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
    @Environment(TabCoordinator.self) private var tabCoordinator   
    @Environment(UserSession.self) private var session

    
    @FocusState private var isInputFocused: Bool
    
    // MARK: - Background
    
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
    
    // MARK: - Layout
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerSection
            messagesSection
            inputSection
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.`2xl`) {
            HStack(spacing: Theme.Spacing.lg) {
                weatherBadge
                scheduleBadge
                moodBadge
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
                Text("\(weather.emoji) \(weather.tempF)°F")
                    .themeFont(size: .base, weight: .semiBold)
                    .foregroundColor(Theme.Colors.textBlue)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Theme.Colors.accentBlue)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                            .stroke(Theme.Colors.accentBlueMedium, lineWidth: 1)
                    )
                    .cornerRadius(Theme.BorderRadius.md)
            } else {
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
                .background(Theme.Colors.accentBlue)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                        .stroke(Theme.Colors.accentBlueMedium, lineWidth: 1)
                )
                .cornerRadius(Theme.BorderRadius.md)
            }
        }
    }
    
    private var scheduleBadge: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "clock")
                .font(.system(size: 18))
                .foregroundColor(Theme.Colors.textPrimary)
            Text("Free until 6:30 PM")
                .themeFont(size: .base, weight: .semiBold)
                .foregroundColor(Theme.Colors.textPrimary)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.glassBackground)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
        .cornerRadius(Theme.BorderRadius.md)
    }
    
    private var moodBadge: some View {
        Text("Chill ✨")
            .themeFont(size: .base, weight: .semiBold)
            .foregroundColor(Theme.Colors.textSecondary)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colors.whiteOverlay)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
            .cornerRadius(Theme.BorderRadius.md)
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
    
    // MARK: - Messages
    
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
        // Recommendation bundle from backend
        if message.type == .recommendations, let recommendations = message.recommendations {
            VStack(spacing: Theme.Spacing.`2xl`) {
                ForEach(recommendations) { recommendation in
                    RecommendationCard(
                        recommendation: recommendation,
                        session: session,
                        preferences: session.preferences
                    ) {
                        let place = SelectedPlace(
                            name: recommendation.title,
                            latitude: recommendation.lat ?? 40.693393,
                            longitude: recommendation.lng ?? -73.98555,
                            walkTime: recommendation.walkTime,
                            distance: recommendation.distance,
                            address: recommendation.description,
                            image: recommendation.image
                        )
                        // 1. Save selected place for Map
                        placeViewModel.setSelectedPlace(place)
                        // 2. Jump to Map tab
                        tabCoordinator.selectedTab = .map
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.`2xl`)
            .padding(.top, Theme.Spacing.`2xl`)
        }
        // Normal text messages
        else if let content = message.content {
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
    
    // MARK: - Input
    
    private var inputSection: some View {
        InputField(placeholder: "Ask VioletVibes...", isFocused: $isInputFocused) { text in
            Task {
                await chatViewModel.sendMessage(
                    text,
                    latitude: locationManager.location?.coordinate.latitude,
                    longitude: locationManager.location?.coordinate.longitude,
                    session: session,
                    preferences: session.preferences
                )
            }
        }
        .padding(.horizontal, Theme.Spacing.`2xl`)
        .padding(.bottom, Theme.Spacing.`2xl`)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            backgroundGradient
                .onTapGesture {
                    // Dismiss keyboard when tapping background
                    isInputFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            mainContent
        }
        .task {
            if let jwt = session.jwt {
                await weatherManager.loadWeather()
            }
        }
        .onChange(of: session.jwt) { _, newJWT in
            if let jwt = newJWT {
                Task {
                    print("🔑 JWT changed → ChatView loading weather")
                    await weatherManager.loadWeather()
                }
            }
        }
        .onChange(of: locationManager.location) { _, newValue in
            if newValue != nil, let jwt = session.jwt {
                Task {
                    print("📍 Location changed → reloading weather")
                    await weatherManager.loadWeather()
                }
            }
        }

    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    let content: String
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading,
                   spacing: Theme.Spacing.xs) {
                
                // Text with markdown-ish formatting
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
            .frame(
                maxWidth: UIScreen.main.bounds.width * 0.75,
                alignment: message.role == .user ? .trailing : .leading
            )
            
            if message.role == .ai {
                Spacer()
            }
        }
    }
    
    // MARK: - Time formatting
    
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
    
    // MARK: - Text formatting
    
    @ViewBuilder
    private func formattedText(_ text: String) -> some View {
        let cleanedText = cleanAndFormatText(text)
        
        if #available(iOS 15.0, *) {
            if let attributedString = try? AttributedString(markdown: cleanedText) {
                let styledString = applyParagraphSpacing(to: attributedString)
                Text(styledString)
            } else {
                Text(cleanedText)
                    .lineSpacing(4)
            }
        } else {
            Text(cleanedText)
                .lineSpacing(4)
        }
    }
    
    @available(iOS 15.0, *)
    private func applyParagraphSpacing(to attributedString: AttributedString) -> AttributedString {
        var styledString = attributedString
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 12
        paragraphStyle.paragraphSpacingBefore = 8
        paragraphStyle.lineSpacing = 4
        
        let paragraphStyleAttribute = AttributeContainer([.paragraphStyle: paragraphStyle])
        styledString.mergeAttributes(paragraphStyleAttribute, mergePolicy: .keepNew)
        
        return styledString
    }
    
    private func cleanAndFormatText(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var formattedLines: [String] = []
        
        for line in lines {
            var processedLine = line
            processedLine = processedLine.replacingOccurrences(
                of: "[ \t]+",
                with: " ",
                options: .regularExpression
            )
            processedLine = processedLine.trimmingCharacters(in: .whitespaces)
            
            if processedLine.isEmpty {
                if !formattedLines.isEmpty && !formattedLines.last!.isEmpty {
                    formattedLines.append("")
                }
                continue
            }
            
            let trimmed = processedLine.trimmingCharacters(in: .whitespaces)
            
            // Convert basic markdown lists to bullets
            if trimmed.hasPrefix("* ") {
                let afterMarker = String(trimmed.dropFirst(2))
                if !trimmed.contains("**") || !trimmed.hasPrefix("**") {
                    processedLine = "• " + afterMarker
                }
            } else if trimmed.hasPrefix("- ") {
                processedLine = "• " + String(trimmed.dropFirst(2))
            }
            
            formattedLines.append(processedLine)
        }
        
        var cleaned = formattedLines.joined(separator: "\n")
        
        // Spaces around em dash
        cleaned = cleaned.replacingOccurrences(
            of: "([^ ])—",
            with: "$1 — ",
            options: .regularExpression
        )
        cleaned = cleaned.replacingOccurrences(
            of: "—([^ ])",
            with: " — $1",
            options: .regularExpression
        )
        
        // Extra paragraph breaks after ! ? .
        cleaned = cleaned.replacingOccurrences(
            of: "([!?])\\s+([A-Z])",
            with: "$1\n\n$2",
            options: .regularExpression
        )
        cleaned = cleaned.replacingOccurrences(
            of: "\\.\\s+([A-Z][a-z]{2,})",
            with: ".\n\n$1",
            options: .regularExpression
        )
        
        // Line breaks before bullets
        cleaned = cleaned.replacingOccurrences(
            of: "([^\n])(• )",
            with: "$1\n\n$2",
            options: .regularExpression
        )
        
        // Break after colons before bullets
        cleaned = cleaned.replacingOccurrences(
            of: ":([^\n])(• )",
            with: ":\n\n$1$2",
            options: .regularExpression
        )
        
        // Collapse huge gaps
        cleaned = cleaned.replacingOccurrences(
            of: "\n{3,}",
            with: "\n\n",
            options: .regularExpression
        )
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
