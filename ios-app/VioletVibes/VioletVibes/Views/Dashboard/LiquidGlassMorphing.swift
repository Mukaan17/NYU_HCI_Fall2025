//
//  LiquidGlassMorphing.swift
//  VioletVibes
//
//  Liquid glass morphing animation based on Apple's documentation
//  Implements the morphing droplet effect with spring physics

import SwiftUI

struct LiquidGlassMorphingModifier: ViewModifier {
    @Binding var isVisible: Bool
    var cornerRadius: CGFloat = 12
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.85)
            .offset(y: isVisible ? 0 : -15)
            .blur(radius: isVisible ? 0 : 8)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.75, blendDuration: 0.25),
                value: isVisible
            )
    }
}

extension View {
    func liquidGlassMorph(isVisible: Binding<Bool>, cornerRadius: CGFloat = 12) -> some View {
        modifier(LiquidGlassMorphingModifier(isVisible: isVisible, cornerRadius: cornerRadius))
    }
}
