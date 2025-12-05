//
//  UserPreferences.swift
//  VioletVibes
//
//  Created by Mukhil Sundararaj on 11/25/25.
//


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
    var notificationsEnabled: Bool
    var usePreferencesForPersonalization: Bool
    
    init(
        categories: Set<String> = [],
        budgetMin: Int? = nil,
        budgetMax: Int? = nil,
        dietaryRestrictions: Set<String> = [],
        maxWalkMinutes: Int? = nil,
        hobbies: String? = nil,
        notificationsEnabled: Bool = false,
        usePreferencesForPersonalization: Bool = true
    ) {
        self.categories = categories
        self.budgetMin = budgetMin
        self.budgetMax = budgetMax
        self.dietaryRestrictions = dietaryRestrictions
        self.maxWalkMinutes = maxWalkMinutes
        self.hobbies = hobbies
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

// MARK: - Backend DTOs

struct BackendBudgetPayload: Codable, Sendable {
    var min: Int?
    var max: Int?
}

struct BackendPreferencesPayload: Codable, Sendable {
    var preferred_vibes: [String]?
    var budget: BackendBudgetPayload?
    var dietary_restrictions: [String]?
    var max_walk_minutes_default: Int?
    var interests: String?
}

struct BackendSettingsPayload: Codable, Sendable {
    var google_calendar_enabled: Bool?
    var notifications_enabled: Bool?
    var use_preferences_for_personalization: Bool?
}

// MARK: - Mapping: App → Backend

extension UserPreferences {
    
    func toBackendPreferencesPayload() -> BackendPreferencesPayload {
        // Map categories to backend vibes
        let vibes = categories.compactMap { uiCategoryToBackendVibe($0) }
        
        // Map dietary restrictions to backend format
        let backendDiets = dietaryRestrictions.compactMap { uiDietToBackendDiet($0) }
        let dietList = backendDiets.isEmpty ? nil : backendDiets
        
        // Create budget payload
        var budgetPayload: BackendBudgetPayload? = nil
        if budgetMin != nil || budgetMax != nil {
            budgetPayload = BackendBudgetPayload(min: budgetMin, max: budgetMax)
        }
        
        return BackendPreferencesPayload(
            preferred_vibes: vibes.isEmpty ? nil : vibes,
            budget: budgetPayload,
            dietary_restrictions: dietList,
            max_walk_minutes_default: maxWalkMinutes,
            interests: hobbies?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
    
    /// Build / update UserPreferences from backend JSON.
    /// If `existing` is provided, we keep UI-only fields (like toggles) from it.
    static func fromBackendPreferencesPayload(
        _ backend: BackendPreferencesPayload?,
        existing: UserPreferences? = nil
    ) -> UserPreferences {
        var prefs = existing ?? UserPreferences()
        
        guard let backend = backend else {
            return prefs
        }
        
        // Vibes → categories
        if let vibes = backend.preferred_vibes {
            let uiCats = vibes.compactMap { backendVibeToUICategory($0) }
            prefs.categories = Set(uiCats)
        }
        
        // Budget
        if let b = backend.budget {
            prefs.budgetMin = b.min
            prefs.budgetMax = b.max
        } else {
            prefs.budgetMin = nil
            prefs.budgetMax = nil
        }
        
        // Dietary restrictions
        if let diets = backend.dietary_restrictions {
            let uiDiets = diets.compactMap { backendDietToUIDiet($0) }
            prefs.dietaryRestrictions = Set(uiDiets)
        }
        
        // Max walk minutes
        prefs.maxWalkMinutes = backend.max_walk_minutes_default
        
        // Interests
        prefs.hobbies = backend.interests
        
        return prefs
    }
    
    /// Merge backend settings into preferences
    static func mergedWithSettings(
        _ prefs: UserPreferences,
        backendSettings: BackendSettingsPayload?
    ) -> UserPreferences {
        var merged = prefs
        
        guard let settings = backendSettings else {
            return merged
        }
        
        
        if let notificationsEnabled = settings.notifications_enabled {
            merged.notificationsEnabled = notificationsEnabled
        }
        
        if let usePrefs = settings.use_preferences_for_personalization {
            merged.usePreferencesForPersonalization = usePrefs
        }
        
        return merged
    }
}

// MARK: - Category Mapping

fileprivate func uiCategoryToBackendVibe(_ category: String) -> String? {
    let trimmed = category.lowercased()
    
    if trimmed.contains("study") || trimmed.contains("café") || trimmed.contains("cafe") {
        return "study"
    }
    if trimmed.contains("free events") || trimmed.contains("pop-ups") || trimmed.contains("pop ups") {
        return "free_events"
    }
    if trimmed.contains("food around campus") || trimmed.contains("food") {
        return "food"
    }
    if trimmed.contains("nightlife") {
        return "nightlife"
    }
    if trimmed.contains("explore") || trimmed.contains("open to anything") {
        return "explore"
    }
    
    return nil
}

fileprivate func backendVibeToUICategory(_ vibe: String) -> String? {
    switch vibe.lowercased() {
    case "study", "study_spots":
        return "Study Spots"
    case "free_events":
        return "Free Events"
    case "food":
        return "Food"
    case "nightlife":
        return "Nightlife"
    case "explore":
        return "Explore All"
    default:
        return nil
    }
}

// MARK: - Dietary Mapping

fileprivate func uiDietToBackendDiet(_ ui: String) -> String? {
    switch ui.lowercased() {
    case "vegetarian": return "vegetarian"
    case "vegan": return "vegan"
    case "halal": return "halal"
    case "kosher": return "kosher"
    case "gluten-free": return "gluten-free"
    case "dairy-free": return "dairy-free"
    case "pork-free": return "pork-free"
    case "seafood allergy": return "seafood-allergy"
    default:
        // "Other" or unknown → don't send to backend
        return nil
    }
}

fileprivate func backendDietToUIDiet(_ backend: String) -> String? {
    switch backend.lowercased() {
    case "vegetarian": return "Vegetarian"
    case "vegan": return "Vegan"
    case "halal": return "Halal"
    case "kosher": return "Kosher"
    case "gluten-free": return "Gluten-Free"
    case "dairy-free": return "Dairy-Free"
    case "pork-free": return "Pork-Free"
    case "seafood-allergy": return "Seafood Allergy"
    default:
        return nil
    }
}

