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
    
    @FocusState private var isInputFocused: Bool
    
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
                Text("\(weather.emoji) \(weather.temp)°F")
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
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        isInputFocused = false
                    }
            )
            .simultaneousGesture(
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
                    longitude: locationManager.location?.coordinate.longitude
                )
            }
        }
        .padding(.horizontal, Theme.Spacing.`2xl`)
        .padding(.bottom, Theme.Spacing.`2xl`)
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
            mainContent
        }
            .task {
                // Load weather on task start (app launch/restart)
                await weatherManager.loadWeather(locationManager: locationManager)
            }
            .onChange(of: locationManager.location) { oldValue, newValue in
                // Reload weather when location changes
                if newValue != nil {
                    Task {
                        await weatherManager.loadWeather(locationManager: locationManager)
                    }
                }
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
            // Try to parse as markdown with better formatting
            if let attributedString = try? AttributedString(markdown: cleanedText) {
                // Add paragraph spacing to the attributed string
                let styledString = applyParagraphSpacing(to: attributedString)
                Text(styledString)
            } else {
                // Fallback: display cleaned text with line spacing
                Text(cleanedText)
                    .lineSpacing(4)
            }
        } else {
            Text(cleanedText)
                .lineSpacing(4)
        }
    }
    
    // Apply paragraph spacing to an AttributedString
    @available(iOS 15.0, *)
    private func applyParagraphSpacing(to attributedString: AttributedString) -> AttributedString {
        var styledString = attributedString
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 12
        paragraphStyle.paragraphSpacingBefore = 8
        paragraphStyle.lineSpacing = 4
        
        // Apply paragraph style to entire string
        let paragraphStyleAttribute = AttributeContainer([.paragraphStyle: paragraphStyle])
        styledString.mergeAttributes(paragraphStyleAttribute, mergePolicy: .keepNew)
        
        return styledString
    }
    
    // Clean and format text for better readability
    private func cleanAndFormatText(_ text: String) -> String {
        // Process line by line to handle formatting properly
        let lines = text.components(separatedBy: .newlines)
        var formattedLines: [String] = []
        
        for line in lines {
            var processedLine = line
            
            // Replace multiple spaces/tabs with single space
            processedLine = processedLine.replacingOccurrences(of: "[ \t]+", with: " ", options: .regularExpression)
            
            // Trim whitespace but preserve the line structure
            processedLine = processedLine.trimmingCharacters(in: .whitespaces)
            
            if processedLine.isEmpty {
                // Only add empty line if previous line wasn't empty
                if !formattedLines.isEmpty && !formattedLines.last!.isEmpty {
                    formattedLines.append("")
                }
                continue
            }
            
            // Check if this is a list item - must start with * or - followed by space
            // But NOT if it's part of markdown formatting (**bold** or *italic*)
            let trimmed = processedLine.trimmingCharacters(in: .whitespaces)
            
            // Convert list markers to bullet points
            // Only if it starts with "* " or "- " and is not markdown formatting
            if trimmed.hasPrefix("* ") {
                // Check if it's not part of **bold** formatting
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
        
        // Ensure proper spacing around em dashes
        cleaned = cleaned.replacingOccurrences(of: "([^ ])—", with: "$1 — ", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "—([^ ])", with: " — $1", options: .regularExpression)
        
        // Add paragraph breaks after sentences ending with ! or ? followed by capital letters
        cleaned = cleaned.replacingOccurrences(of: "([!?])\\s+([A-Z])", with: "$1\n\n$2", options: .regularExpression)
        
        // Add paragraph breaks after periods followed by capital letters (new sentences)
        cleaned = cleaned.replacingOccurrences(of: "\\.\\s+([A-Z][a-z]{2,})", with: ".\n\n$1", options: .regularExpression)
        
        // Add line breaks before list items (bullet points) if they're on the same line
        cleaned = cleaned.replacingOccurrences(of: "([^\n])(• )", with: "$1\n\n$2", options: .regularExpression)
        
        // Add line breaks after colons if followed by a list
        cleaned = cleaned.replacingOccurrences(of: ":([^\n])(• )", with: ":\n\n$1$2", options: .regularExpression)
        
        // Clean up multiple newlines (max 2 consecutive for paragraph breaks)
        cleaned = cleaned.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        
        // Trim whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
}

