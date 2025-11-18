//
//  ChatView.swift
//  VioletVibes
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var placeViewModel: PlaceViewModel
    @EnvironmentObject var locationManager: LocationManager
    
    @State private var weather: Weather?
    
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
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: Theme.Spacing.`2xl`) {
                    HStack(spacing: Theme.Spacing.lg) {
                        // Weather Badge
                        if let weather = weather {
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
                        }
                        
                        // Schedule Badge
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
                        
                        // Mood Badge
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
                }
                .padding(.top, Theme.Spacing.`2xl`)
                .padding(.bottom, Theme.Spacing.`2xl`)
                .padding(.horizontal, Theme.Spacing.`2xl`)
                .background(
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
                )
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Theme.Colors.borderLight),
                    alignment: .bottom
                )
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.xl) {
                            ForEach(chatViewModel.messages) { message in
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
                            
                            if chatViewModel.isTyping {
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
                        }
                        .padding(.top, Theme.Spacing.`3xl`)
                        .padding(.bottom, 120)
                    }
                    .onChange(of: chatViewModel.messages.count) { _ in
                        if let lastMessage = chatViewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input
                InputField(placeholder: "Ask VioletVibes...") { text in
                    Task {
                        await chatViewModel.sendMessage(
                            text,
                            latitude: locationManager.location?.coordinate.latitude,
                            longitude: locationManager.location?.coordinate.longitude
                        )
                    }
                }
                .padding(.horizontal, Theme.Spacing.`2xl`)
                .padding(.bottom, 75)
            }
        }
        .task {
            if let location = locationManager.location {
                if let w = await WeatherService.shared.getWeather(
                    lat: location.coordinate.latitude,
                    lon: location.coordinate.longitude
                ) {
                    weather = w
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
                Text(content)
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
}

