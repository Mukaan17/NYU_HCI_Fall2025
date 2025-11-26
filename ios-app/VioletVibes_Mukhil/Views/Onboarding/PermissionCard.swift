//
//  PermissionCard.swift
//  VioletVibes
//

import SwiftUI

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let isEnabled: Bool
    
    var body: some View {
        VStack(spacing: Theme.Spacing.`2xl`) {
            // Icon Container with glass effect
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        LinearGradient(
                            colors: [
                                Theme.Colors.gradientStart.opacity(0.35),
                                Theme.Colors.gradientStart.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Theme.Colors.gradientStart.opacity(0.3), lineWidth: 1)
                    )
                    .frame(width: 96, height: 96)
                    .shadow(color: Theme.Colors.gradientStart.opacity(0.4), radius: 20, x: 0, y: 8)
                
                Text(icon)
                    .font(.system(size: 48))
            }
            
            // Title
            Text(title)
                .themeFont(size: .`2xl`, weight: .bold)
                .foregroundColor(Theme.Colors.textPrimary)
            
            // Description
            Text(description)
                .themeFont(size: .base)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: 280)
        }
        .padding(.vertical, Theme.Spacing.md)
    }
}

