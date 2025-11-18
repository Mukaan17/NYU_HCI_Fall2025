//
//  SafetyView.swift
//  VioletVibes
//

import SwiftUI

struct SafetyView: View {
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Theme.Colors.background,
                    Theme.Colors.backgroundSecondary,
                    Theme.Colors.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Blur Shape
            GeometryReader { geometry in
                Circle()
                    .fill(Theme.Colors.accentError.opacity(0.05))
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .blur(radius: 100)
            }
            
            ScrollView {
                VStack(spacing: Theme.Spacing.`6xl`) {
                    // Header
                    VStack(spacing: Theme.Spacing.`2xl`) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.accentError.opacity(0.1))
                                .frame(width: 80, height: 80)
                                .blur(radius: 40)
                            
                            Circle()
                                .fill(Theme.Colors.backgroundCard)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(Theme.Colors.border, lineWidth: 1)
                                )
                            
                            Text("🛡️")
                                .font(.system(size: 40))
                        }
                        
                        Text("Safety Center")
                            .themeFont(size: .`3xl`, weight: .bold)
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Text("We're here to keep you safe")
                            .themeFont(size: .lg)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .padding(.top, Theme.Spacing.`6xl`)
                    
                    // Action Buttons
                    VStack(spacing: Theme.Spacing.`2xl`) {
                        // Call NYU Public Safety
                        Button(action: {
                            if let url = URL(string: "tel:2129982222") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                        .fill(Theme.Colors.accentError)
                                        .frame(width: 48, height: 48)
                                    
                                    Text("📞")
                                        .font(.system(size: 24))
                                }
                                
                                Text("Call NYU Public Safety")
                                    .themeFont(size: .lg, weight: .semiBold)
                                    .foregroundColor(Theme.Colors.textError)
                                
                                Spacer()
                                
                                Text("→")
                                    .themeFont(size: .xl)
                                    .foregroundColor(Theme.Colors.textPrimary)
                            }
                            .padding(Theme.Spacing.`2xl`)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                    .stroke(Theme.Colors.accentErrorBorder, lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Share Live Location
                        Button(action: {
                            // TODO: Implement location sharing
                        }) {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                        .fill(Theme.Colors.whiteOverlayMedium)
                                        .frame(width: 48, height: 48)
                                    
                                    Text("📍")
                                        .font(.system(size: 24))
                                }
                                
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text("Share Live Location")
                                        .themeFont(size: .lg, weight: .semiBold)
                                        .foregroundColor(Theme.Colors.textPrimary)
                                    
                                    Text("With trusted contacts")
                                        .themeFont(size: .sm)
                                        .foregroundColor(Color.white.opacity(0.7))
                                }
                                
                                Spacer()
                            }
                            .padding(Theme.Spacing.`3xl`)
                            .background(
                                LinearGradient(
                                    colors: [Theme.Colors.gradientStart, Theme.Colors.gradientEnd],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(Theme.BorderRadius.md)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Find Safe Route
                        Button(action: {
                            // TODO: Implement safe route finding
                        }) {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                        .fill(Theme.Colors.whiteOverlayMedium)
                                        .frame(width: 48, height: 48)
                                    
                                    Text("🛣️")
                                        .font(.system(size: 24))
                                }
                                
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text("Find a Safe Route Home")
                                        .themeFont(size: .lg, weight: .semiBold)
                                        .foregroundColor(Theme.Colors.textPrimary)
                                    
                                    Text("Well-lit paths")
                                        .themeFont(size: .sm)
                                        .foregroundColor(Color.white.opacity(0.7))
                                }
                                
                                Spacer()
                            }
                            .padding(Theme.Spacing.`3xl`)
                            .background(
                                LinearGradient(
                                    colors: [Theme.Colors.gradientBlueStart, Theme.Colors.gradientBlueEnd],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(Theme.BorderRadius.md)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Emergency Contacts
                    VStack(spacing: Theme.Spacing.`2xl`) {
                        HStack {
                            Text("Emergency Services")
                                .themeFont(size: .base)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            Spacer()
                            
                            Button(action: {
                                if let url = URL(string: "tel:911") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("911")
                                    .themeFont(size: .md, weight: .semiBold)
                                    .foregroundColor(Theme.Colors.textPrimary)
                            }
                        }
                        .padding(.vertical, Theme.Spacing.`2xl`)
                        
                        Divider()
                            .background(Theme.Colors.whiteOverlay)
                        
                        HStack {
                            Text("NYU Public Safety")
                                .themeFont(size: .base)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            Spacer()
                            
                            Button(action: {
                                if let url = URL(string: "tel:2129982222") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("(212) 998-2222")
                                    .themeFont(size: .md, weight: .semiBold)
                                    .foregroundColor(Theme.Colors.textPrimary)
                            }
                        }
                        .padding(.vertical, Theme.Spacing.`2xl`)
                    }
                    .padding(Theme.Spacing.`3xl`)
                    .background(Theme.Colors.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.BorderRadius.lg)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                    .cornerRadius(Theme.BorderRadius.lg)
                    .padding(.horizontal, Theme.Spacing.`2xl`)
                    .padding(.bottom, 180)
                }
            }
        }
    }
}

