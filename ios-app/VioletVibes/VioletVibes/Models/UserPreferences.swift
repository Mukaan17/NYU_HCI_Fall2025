//
//  UserPreferences.swift
//  VioletVibes
//

import Foundation

struct UserPreferences: Codable, Equatable {
    var categories: Set<String> // Study Spots, Free Events, Food, Nightlife, Explore All
    var budgetMin: Int?
    var budgetMax: Int?
    var dietaryRestrictions: Set<String> // Vegetarian, Vegan, Halal, Kosher, etc.
    var maxWalkMinutes: Int? // 5, 10, 15, 20, or nil for no preference
    var hobbies: String?
    var googleCalendarEnabled: Bool
    var notificationsEnabled: Bool
    var usePreferencesForPersonalization: Bool
    
    init(
        categories: Set<String> = [],
        budgetMin: Int? = nil,
        budgetMax: Int? = nil,
        dietaryRestrictions: Set<String> = [],
        maxWalkMinutes: Int? = nil,
        hobbies: String? = nil,
        googleCalendarEnabled: Bool = false,
        notificationsEnabled: Bool = false,
        usePreferencesForPersonalization: Bool = true
    ) {
        self.categories = categories
        self.budgetMin = budgetMin
        self.budgetMax = budgetMax
        self.dietaryRestrictions = dietaryRestrictions
        self.maxWalkMinutes = maxWalkMinutes
        self.hobbies = hobbies
        self.googleCalendarEnabled = googleCalendarEnabled
        self.notificationsEnabled = notificationsEnabled
        self.usePreferencesForPersonalization = usePreferencesForPersonalization
    }
    
    // MARK: - Helper Methods
    
    /// Returns budget range as formatted string (e.g., "$ - $$")
    var budgetDisplay: String {
        guard let min = budgetMin, let max = budgetMax else {
            return "No preference"
        }
        
        let minSymbol = budgetSymbol(for: min)
        let maxSymbol = budgetSymbol(for: max)
        
        if minSymbol == maxSymbol {
            return minSymbol
        } else {
            return "\(minSymbol) - \(maxSymbol)"
        }
    }
    
    /// Converts budget value to symbol
    private func budgetSymbol(for value: Int) -> String {
        if value <= 20 {
            return "$"
        } else if value <= 50 {
            return "$$"
        } else {
            return "$$$"
        }
    }
    
    /// Returns walking distance as formatted string
    var walkingDistanceDisplay: String {
        guard let minutes = maxWalkMinutes else {
            return "No preference"
        }
        return "\(minutes) min"
    }
}

