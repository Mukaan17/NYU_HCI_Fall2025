//
//  WeatherDropdownOverlay.swift
//  VioletVibes
//

import SwiftUI

// PreferenceKey to track weather button frame
struct WeatherButtonFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// Weather dropdown overlay component
struct WeatherDropdownOverlay: View {
    let currentWeather: Weather?
    let forecast: [HourlyForecast]?
    @Binding var isExpanded: Bool
    let buttonFrame: CGRect
    
    var body: some View {
        if isExpanded && buttonFrame != .zero {
            GeometryReader { geometry in
                let screenWidth = geometry.size.width
                let screenHeight = geometry.size.height
                let safeAreaPadding: CGFloat = 16
                
                // Get GeometryReader's frame in global coordinates
                let geometryGlobalFrame = geometry.frame(in: .global)
                
                // Convert button's global coordinates to GeometryReader's local coordinates
                let buttonLeftX = buttonFrame.minX - geometryGlobalFrame.minX
                let buttonY = buttonFrame.maxY - geometryGlobalFrame.minY
                
                // Calculate dynamic width: extend from left edge of pill to the right
                let maxDropdownWidth = screenWidth - buttonLeftX - safeAreaPadding
                let preferredWidth: CGFloat = 320
                let dropdownWidth = min(preferredWidth, maxDropdownWidth)
                let centerX = buttonLeftX + dropdownWidth / 2
                let dropdownY = buttonY + 12 + 90
                
                // Calculate dropdown frame in GeometryReader's local coordinates
                let dropdownFrame = CGRect(
                    x: centerX - dropdownWidth / 2,
                    y: dropdownY - 90,
                    width: dropdownWidth,
                    height: 180
                )
                
                ZStack {
                    // Full-screen transparent background to capture taps outside the overlay
                    Rectangle()
                        .fill(Color.black.opacity(0.0001))
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                        // Block vertical scrolling on the background (outside dropdown)
                        // This prevents underlying ScrollView from scrolling when dragging outside dropdown
                        .highPriorityGesture(
                            DragGesture()
                                .onChanged { value in
                                    // Only block vertical drags on the background
                                    let verticalMovement = abs(value.translation.height)
                                    let horizontalMovement = abs(value.translation.width)
                                    
                                    // Block vertical drags to prevent underlying ScrollView scrolling
                                    if verticalMovement > horizontalMovement && verticalMovement > 5 {
                                        // Consume vertical gesture
                                    }
                                }
                        )
                    
                    // Dropdown content - fixed height, no vertical scrolling
                    VStack(spacing: Theme.Spacing.md) {
                        // Current weather display - always show if available
                        if let weather = currentWeather {
                            VStack(spacing: Theme.Spacing.xs) {
                                Text(weather.emoji)
                                    .font(.system(size: 40))
                                
                                Text("\(weather.temp)°F")
                                    .themeFont(size: .xl, weight: .bold)
                                    .foregroundColor(Theme.Colors.textPrimary)
                            }
                            .padding(.vertical, Theme.Spacing.sm)
                            .fixedSize(horizontal: false, vertical: true)
                        } else {
                            // Placeholder for current weather when loading
                            VStack(spacing: Theme.Spacing.xs) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(Theme.Colors.textPrimary)
                            }
                            .padding(.vertical, Theme.Spacing.sm)
                            .frame(height: 60)
                        }
                        
                        // Hourly forecast scroll view - horizontal only
                        if let forecast = forecast, !forecast.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Theme.Spacing.sm) {
                                    ForEach(forecast.prefix(12)) { hour in
                                        HourlyForecastCompactCard(forecast: hour)
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.sm)
                            }
                            .scrollBounceBehavior(.basedOnSize)
                            .frame(height: 100)
                        } else {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(Theme.Colors.textPrimary)
                                Text("Loading forecast...")
                                    .themeFont(size: .sm)
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                            .frame(height: 100)
                        }
                    }
                    .padding(Theme.Spacing.md)
                    .frame(width: dropdownWidth, height: 180) // Fixed frame - no expansion, padding included
                    .fixedSize(horizontal: false, vertical: true) // Prevent vertical expansion
                    .clipped() // Prevent content from overflowing
                    .background(Theme.Colors.glassBackgroundLight) // More opaque
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                    .cornerRadius(Theme.BorderRadius.md)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                    .position(
                        x: centerX, // Center X position - left edge will be at buttonLeftX
                        y: buttonY + 12 + 90 // Position below button: gap (12pt) + half dropdown height (90pt)
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .allowsHitTesting(true) // Allow interactions with the dropdown content
                    .contentShape(Rectangle()) // Define hit testing area - only within dropdown bounds
                }
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Handle taps outside the dropdown - use simultaneousGesture so it doesn't block ScrollView
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            // Check if tap/drag ended outside dropdown frame
                            if !dropdownFrame.contains(value.location) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isExpanded = false
                                }
                            }
                        }
                )
            }
        }
    }
}

struct HourlyForecastCompactCard: View {
    let forecast: HourlyForecast
    
    private var timeString: String {
        let formatter = DateFormatter()
        let now = Date()
        let calendar = Calendar.current
        
        // Check if it's the current hour
        if calendar.isDate(forecast.time, equalTo: now, toGranularity: .hour) {
            return "Now"
        }
        
        formatter.dateFormat = "h a"
        return formatter.string(from: forecast.time)
    }
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            // Time
            Text(timeString)
                .themeFont(size: .xs, weight: .semiBold)
                .foregroundColor(Theme.Colors.textSecondary)
            
            // Weather emoji
            Text(forecast.emoji)
                .font(.system(size: 24))
            
            // Temperature
            Text("\(forecast.temp)°")
                .themeFont(size: .sm, weight: .semiBold)
                .foregroundColor(Theme.Colors.textPrimary)
        }
        .padding(.vertical, Theme.Spacing.xs)
        .padding(.horizontal, Theme.Spacing.sm)
        .frame(minWidth: 60)
        .background(Theme.Colors.backgroundCard.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.BorderRadius.sm)
                .stroke(Theme.Colors.border.opacity(0.5), lineWidth: 1)
        )
        .cornerRadius(Theme.BorderRadius.sm)
    }
}

