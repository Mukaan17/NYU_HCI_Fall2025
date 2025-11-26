//
//  PrimaryButton.swift
//  VioletVibes
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var disabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .themeFont(size: .lg, weight: .bold)
                .foregroundColor(Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.lg)
                .padding(.horizontal, Theme.Spacing.`2xl`)
                .background(
                    LinearGradient(
                        colors: [Theme.Colors.gradientStart, Theme.Colors.gradientEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(Theme.BorderRadius.md)
        }
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1.0)
    }
}

