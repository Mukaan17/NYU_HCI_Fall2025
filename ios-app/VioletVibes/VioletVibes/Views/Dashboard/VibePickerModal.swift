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
                
                // Convert button's global coordinates to ZStack's local coordinates
                let buttonX = buttonFrame.midX - zStackGlobalFrame.minX
                let buttonY = buttonFrame.maxY - zStackGlobalFrame.minY
                
                VStack(spacing: 0) {
                    Picker("Vibe", selection: Binding(
                        get: { selectedVibe ?? availableVibes.first! },
                        set: { newVibe in
                            selectedVibe = newVibe
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isExpanded = false
                            }
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
                .frame(width: 200, height: 180)
                .position(
                    x: buttonX,
                    y: buttonY + 90 // Position below button (half dropdown height + spacing)
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
}


