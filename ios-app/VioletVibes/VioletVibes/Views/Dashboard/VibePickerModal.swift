//
//  VibePickerModal.swift
//  VioletVibes
//

import SwiftUI

// PreferenceKey to track button frame for absolute positioning
struct VibeButtonFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// Make VibeOption available globally
let availableVibes: [VibeOption] = [
    VibeOption(id: "explore", displayName: "Explore", emoji: "🌍", backendValue: "explore"),
    VibeOption(id: "study", displayName: "Study", emoji: "📚", backendValue: "study"),
    VibeOption(id: "food", displayName: "Food", emoji: "🍔", backendValue: "food_general"),
    VibeOption(id: "party", displayName: "Party", emoji: "🎉", backendValue: "party"),
    VibeOption(id: "chill", displayName: "Chill", emoji: "☕", backendValue: "chill_drinks"),
    VibeOption(id: "shopping", displayName: "Shopping", emoji: "🛍️", backendValue: "shopping"),
    VibeOption(id: "fast", displayName: "Quick Bite", emoji: "⚡", backendValue: "fast_bite"),
    VibeOption(id: "generic", displayName: "Anything", emoji: "✨", backendValue: "generic")
]

struct VibeOption: Identifiable, Hashable {
    let id: String
    let displayName: String
    let emoji: String
    let backendValue: String
}

struct VibePickerDropdown: View {
    @Binding var selectedVibe: VibeOption?
    @Binding var isExpanded: Bool
    
    var body: some View {
        // Button that shows current vibe
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: Theme.Spacing.xs) {
                Text(selectedVibe?.emoji ?? "✨")
                Text(selectedVibe?.displayName ?? "Vibe")
                    .themeFont(size: .base, weight: .semiBold)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineLimit(1) // Prevent text wrapping
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.sm)
            .frame(minHeight: 40) // Fixed minimum height to match other bubbles
            .background(Theme.Colors.whiteOverlay)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.BorderRadius.full)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
            .cornerRadius(Theme.BorderRadius.full)
        }
        .buttonStyle(.plain)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: VibeButtonFrameKey.self, value: geometry.frame(in: .global))
            }
        )
    }
}

// Separate overlay component for top-level positioning
struct VibePickerOverlay: View {
    @Binding var selectedVibe: VibeOption?
    @Binding var isExpanded: Bool
    let buttonFrame: CGRect
    
    var body: some View {
        GeometryReader { geometry in
            if isExpanded && buttonFrame != .zero {
                // Get the ZStack's frame in global coordinates
                let zStackGlobalFrame = geometry.frame(in: .global)
                let screenWidth = geometry.size.width
                let safeAreaPadding: CGFloat = 16
                
                // Convert button's global coordinates to ZStack's local coordinates
                let buttonX = buttonFrame.midX - zStackGlobalFrame.minX
                let buttonY = buttonFrame.maxY - zStackGlobalFrame.minY
                
                // Calculate dropdown position to keep it within screen bounds
                let dropdownWidth: CGFloat = 200
                let dropdownHalfWidth = dropdownWidth / 2
                
                // Calculate desired X position (centered on button)
                // Check if dropdown would extend beyond right edge
                let rightEdgeX = screenWidth - dropdownHalfWidth - safeAreaPadding
                let leftEdgeX = dropdownHalfWidth + safeAreaPadding
                let dropdownX: CGFloat = {
                    let centeredX = buttonX
                    if centeredX + dropdownHalfWidth > screenWidth - safeAreaPadding {
                        return rightEdgeX
                    } else if centeredX - dropdownHalfWidth < safeAreaPadding {
                        return leftEdgeX
                    } else {
                        return centeredX
                    }
                }()
                
                // Calculate dropdown frame for tap detection
                let dropdownY = buttonY + 90
                let dropdownFrame = CGRect(
                    x: dropdownX - dropdownHalfWidth,
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
                    
                    // Dropdown content
                    VStack(spacing: 0) {
                        Picker("Vibe", selection: Binding(
                            get: { selectedVibe ?? availableVibes.first! },
                            set: { newVibe in
                                selectedVibe = newVibe
                                // Keep dropdown open - user can continue selecting or close manually
                            }
                        )) {
                            ForEach(availableVibes) { vibe in
                                HStack {
                                    Text(vibe.emoji)
                                    Text(vibe.displayName)
                                }
                                .tag(vibe)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 150)
                    }
                    .padding(Theme.Spacing.sm)
                    .background(Theme.Colors.glassBackgroundLight) // More opaque to match weather dropdown
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                    .cornerRadius(Theme.BorderRadius.md)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                    .frame(width: dropdownWidth, height: 180)
                    .position(
                        x: dropdownX,
                        y: dropdownY // Position below button (half dropdown height + spacing)
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .allowsHitTesting(true) // Allow interactions with the dropdown content
                    .contentShape(Rectangle()) // Define hit testing area - only within dropdown bounds
                }
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            // Check if tap is outside dropdown frame
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


