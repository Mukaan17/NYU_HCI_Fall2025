//
//  MainTabView.swift
//  VioletVibes
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var placeViewModel: PlaceViewModel
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        ZStack {
            // Tab Content
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(Tab.dashboard)
                    .tabItem {
                        Label(Tab.dashboard.label, systemImage: Tab.dashboard.icon)
                    }
                
                ChatView()
                    .tag(Tab.chat)
                    .tabItem {
                        Label(Tab.chat.label, systemImage: Tab.chat.icon)
                    }
                
                MapView()
                    .tag(Tab.map)
                    .tabItem {
                        Label(Tab.map.label, systemImage: Tab.map.icon)
                    }
                
                SafetyView()
                    .tag(Tab.safety)
                    .tabItem {
                        Label(Tab.safety.label, systemImage: Tab.safety.icon)
                    }
            }
            .opacity(0) // Hide default tab bar
            
            // Custom NavBar overlay
            VStack {
                Spacer()
                NavBar(activeTab: selectedTab) { tab in
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                }
                .padding(.horizontal, Theme.Spacing.`2xl`)
                .padding(.bottom, Theme.Spacing.`2xl`)
            }
        }
    }
}

