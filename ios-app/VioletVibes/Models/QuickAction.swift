//
//  QuickAction.swift
//  VioletVibes
//

import Foundation
import SwiftUI

struct QuickAction: Identifiable, Sendable {
    let id: Int
    let icon: String
    let label: String
    let color: Color
    let prompt: String
    
    static let allActions: [QuickAction] = [
        QuickAction(id: 1, icon: "🍔", label: "Quick Bites", color: Color(hex: "6c63ff"), prompt: "quick_bites"),
        QuickAction(id: 2, icon: "☕", label: "Chill Cafes", color: Color(hex: "6c63ff"), prompt: "chill_cafes"),
        QuickAction(id: 3, icon: "🎵", label: "Events", color: Color(hex: "38c4fc"), prompt: "events"),
        QuickAction(id: 4, icon: "🎯", label: "Explore", color: Color(hex: "38c4fc"), prompt: "explore")
    ]
}

