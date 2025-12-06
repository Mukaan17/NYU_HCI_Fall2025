//
//  KeyboardAvoidanceModifier.swift
//  VioletVibes
//
//  Keyboard avoidance modifier that syncs with iOS system keyboard animations

import SwiftUI

struct KeyboardAvoidanceModifier: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                // Extract keyboard frame and animation parameters to match system exactly
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                   let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
                    let height = keyboardFrame.height
                    withAnimation(.easeInOut(duration: duration)) {
                        keyboardHeight = height
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { notification in
                if let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
                    withAnimation(.easeInOut(duration: duration)) {
                        keyboardHeight = 0
                    }
                }
            }
    }
}

extension View {
    /// Applies keyboard avoidance padding that syncs with iOS system keyboard animations
    func keyboardAvoidance() -> some View {
        modifier(KeyboardAvoidanceModifier())
    }
}
