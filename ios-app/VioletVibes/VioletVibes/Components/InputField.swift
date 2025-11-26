//
//  InputField.swift
//  VioletVibes
//

import SwiftUI

struct InputField: View {
    let placeholder: String
    @FocusState.Binding var isFocused: Bool
    let onSend: (String) -> Void
    
    @State private var text: String = ""
    @State private var sendButtonScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: Theme.Spacing.`2xl`) {
            // Text Field
            TextField(placeholder, text: $text)
                .themeFont(size: .lg)
                .foregroundColor(Theme.Colors.textPrimary)
                .submitLabel(.send)
                .focused($isFocused)
                .onSubmit {
                    sendMessage()
                }
            
            // Send Button
            Button(action: sendMessage) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(
                        Group {
                            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                LinearGradient(
                                    colors: [Theme.Colors.border, Theme.Colors.border],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                LinearGradient(
                                    colors: [Theme.Colors.gradientStart, Theme.Colors.gradientEnd],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                        }
                    )
                    .cornerRadius(Theme.BorderRadius.md)
                    .scaleEffect(sendButtonScale)
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, Theme.Spacing.`2xl`)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                    .fill(Theme.Colors.glassBackground.opacity(0.5))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    private func sendMessage() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            sendButtonScale = 0.9
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await MainActor.run {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                sendButtonScale = 1.0
                }
            }
        }
        
        onSend(trimmed)
        text = ""
    }
}

