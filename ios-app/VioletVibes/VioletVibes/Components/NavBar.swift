//
//  NavBar.swift
//  VioletVibes
//

import SwiftUI

enum Tab: String, CaseIterable {
    case dashboard = "dashboard"
    case chat = "chat"
    case map = "map"
    case safety = "safety"
    
    var label: String {
        switch self {
        case .dashboard: return "Home"
        case .chat: return "Chat"
        case .map: return "Map"
        case .safety: return "Safety"
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .chat: return "message.fill"
        case .map: return "map.fill"
        case .safety: return "shield.fill"
        }
    }
}

struct NavBar: View {
    let activeTab: Tab
    let onTabPress: (Tab) -> Void
    
    @State private var highlightOffset: CGFloat = 0
    @State private var highlightWidth: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            let tabWidth = (geometry.size.width - Theme.Spacing.md * 2 - Theme.Spacing.md * CGFloat(Tab.allCases.count - 1)) / CGFloat(Tab.allCases.count)
            
            ZStack(alignment: .leading) {
                // Background blur
                RoundedRectangle(cornerRadius: Theme.BorderRadius.full)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.BorderRadius.full)
                            .fill(Theme.Colors.glassBackground.opacity(0.4))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.BorderRadius.full)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                
                // Highlight blob
                RoundedRectangle(cornerRadius: Theme.BorderRadius.full)
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.accentPurple.opacity(0.35),
                                Theme.Colors.accentPurple.opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: highlightWidth > 0 ? highlightWidth : tabWidth)
                    .offset(x: highlightOffset)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: highlightOffset)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: highlightWidth)
                
                // Tabs
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Button(action: {
                            onTabPress(tab)
                        }) {
                            VStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(activeTab == tab ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                                
                                Text(tab.label)
                                    .themeFont(size: .sm, weight: .semiBold)
                                    .foregroundColor(activeTab == tab ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.md)
                            .padding(.horizontal, Theme.Spacing.md)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .background(
                            GeometryReader { tabGeometry in
                                Color.clear
                                    .preference(
                                        key: TabPreferenceKey.self,
                                        value: [TabPreferenceData(
                                            tab: tab,
                                            bounds: tabGeometry.frame(in: .named("NavBar"))
                                        )]
                                    )
                            }
                        )
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
            }
            .coordinateSpace(name: "NavBar")
            .onPreferenceChange(TabPreferenceKey.self) { preferences in
                if let activePreference = preferences.first(where: { $0.tab == activeTab }) {
                    highlightOffset = activePreference.bounds.minX
                    highlightWidth = activePreference.bounds.width
                }
            }
        }
        .frame(height: 60)
    }
}

struct TabPreferenceData: Equatable {
    let tab: Tab
    let bounds: CGRect
}

struct TabPreferenceKey: PreferenceKey {
    static var defaultValue: [TabPreferenceData] = []
    
    static func reduce(value: inout [TabPreferenceData], nextValue: () -> [TabPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
}

