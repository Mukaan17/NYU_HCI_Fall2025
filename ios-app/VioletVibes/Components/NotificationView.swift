//
//  NotificationView.swift
//  VioletVibes
//

import SwiftUI

struct NotificationView: View {
    let visible: Bool
    let onDismiss: () -> Void
    let onViewEvent: () -> Void
    let message: String
    
    var body: some View {
        if visible {
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        onDismiss()
                    }
                
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: Theme.Spacing.`2xl`) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.backgroundCard)
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Circle()
                                        .stroke(Theme.Colors.borderMedium, lineWidth: 1)
                                )
                            
                            Image(systemName: "sparkles")
                                .foregroundColor(.white)
                                .font(.system(size: 28))
                        }
                        
                        // Text Content
                        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            HStack {
                                Text("VioletVibes")
                                    .themeFont(size: .md, weight: .bold)
                                    .foregroundColor(Theme.Colors.textPrimary)
                                
                                Spacer()
                                
                                Text("now")
                                    .themeFont(size: .xs, weight: .medium)
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                            
                            HStack(spacing: Theme.Spacing.md) {
                                Text("🔔")
                                    .font(.system(size: 16))
                                Text("You're free till 8 PM!")
                                    .themeFont(size: .md, weight: .semiBold)
                                    .foregroundColor(Theme.Colors.textPrimary)
                            }
                            
                            Text(message)
                                .themeFont(size: .base)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .lineLimit(3)
                        }
                    }
                    .padding(Theme.Spacing.`3xl`)
                    
                    Divider()
                        .background(Theme.Colors.border)
                        .padding(.horizontal, Theme.Spacing.`3xl`)
                    
                    // Actions
                    HStack(spacing: Theme.Spacing.xl) {
                        Button(action: onViewEvent) {
                            Text("View Event")
                                .themeFont(size: .sm, weight: .semiBold)
                                .foregroundColor(Theme.Colors.gradientStart)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.Spacing.lg)
                                .background(Theme.Colors.accentPurpleMedium)
                                .cornerRadius(Theme.BorderRadius.md)
                        }
                        
                        Button(action: onDismiss) {
                            Text("Dismiss")
                                .themeFont(size: .sm, weight: .semiBold)
                                .foregroundColor(Theme.Colors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.Spacing.lg)
                                .background(Theme.Colors.whiteOverlay)
                                .cornerRadius(Theme.BorderRadius.md)
                        }
                    }
                    .padding(Theme.Spacing.`3xl`)
                }
                .frame(maxWidth: 361)
                .background(
                    LinearGradient(
                        colors: [Theme.Colors.backgroundCard, Theme.Colors.backgroundCardDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(Theme.BorderRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.BorderRadius.lg)
                        .stroke(Theme.Colors.borderMedium, lineWidth: 1)
                )
            }
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
        }
    }
}

