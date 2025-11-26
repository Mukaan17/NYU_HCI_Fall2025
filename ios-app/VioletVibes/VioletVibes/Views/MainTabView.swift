//
//  MainTabView.swift
//  VioletVibes
//

import SwiftUI

enum AppTab: String, CaseIterable {
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

struct MainTabView: View {
    @State private var selectedTab: AppTab = .dashboard
    @Environment(ChatViewModel.self) private var chatViewModel
    @Environment(PlaceViewModel.self) private var placeViewModel
    @Environment(LocationManager.self) private var locationManager
    
    var body: some View {
            TabView(selection: $selectedTab) {
                DashboardView()
                .tag(AppTab.dashboard)
                    .tabItem {
                    Label(AppTab.dashboard.label, systemImage: AppTab.dashboard.icon)
                    }
                
                ChatView()
                .tag(AppTab.chat)
                    .tabItem {
                    Label(AppTab.chat.label, systemImage: AppTab.chat.icon)
                    }
                
                MapView()
                .tag(AppTab.map)
                    .tabItem {
                    Label(AppTab.map.label, systemImage: AppTab.map.icon)
                    }
                
                SafetyView()
                .tag(AppTab.safety)
                    .tabItem {
                    Label(AppTab.safety.label, systemImage: AppTab.safety.icon)
                    }
            }
        .tint(Theme.Colors.gradientStart) // Apply accent color to active tab
    }
}

