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
            // Icon Container with liquid glass material - rounded square
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(.ultraThinMaterial)
                    .frame(width: 96, height: 96)
                
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
        .background(.clear)
    }
}

