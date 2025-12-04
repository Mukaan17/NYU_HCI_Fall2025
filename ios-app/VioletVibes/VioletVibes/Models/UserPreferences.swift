//
//  UserPreferences.swift
//  VioletVibes
//

import Foundation

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

// MARK: - App-level Preferences

struct UserPreferences: Codable, Sendable, Equatable {
    /// UI categories (pretty labels)
    var categories: Set<String> = []

    /// Budget range in dollars (optional)
    var budgetMin: Int? = nil
    var budgetMax: Int? = nil

    /// Dietary restriction labels as shown in UI
    var dietaryRestrictions: Set<String> = []

    /// Max preferred walk time in minutes
    var maxWalkMinutes: Int? = nil

    /// Free-text hobbies / interests
    var hobbies: String? = nil

    /// Settings (mirrored from backend /settings)
    var googleCalendarEnabled: Bool = false
    var notificationsEnabled: Bool = false
    var usePreferencesForPersonalization: Bool = true
}

// MARK: - Mapping: App → Backend

extension UserPreferences {

    func toBackendPreferencesPayload() -> BackendPreferencesPayload {
        let vibes = categories.compactMap { uiCategoryToBackendVibe($0) }

        let backendDiets = dietaryRestrictions.compactMap { uiDietToBackendDiet($0) }
        let dietList = backendDiets.isEmpty ? nil : backendDiets

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

        // Diets
        if let diets = backend.dietary_restrictions {
            let uiDiets = diets.compactMap { backendDietToUIDiet($0) }
            prefs.dietaryRestrictions = Set(uiDiets)
        } else {
            prefs.dietaryRestrictions = []
        }

        prefs.maxWalkMinutes = backend.max_walk_minutes_default
        prefs.hobbies = backend.interests

        return prefs
    }

    /// Apply backend /settings flags onto a preferences object.
    static func mergedWithSettings(
        _ prefs: UserPreferences,
        backendSettings: BackendSettingsPayload?
    ) -> UserPreferences {
        var copy = prefs
        guard let s = backendSettings else { return copy }

        if let gc = s.google_calendar_enabled {
            copy.googleCalendarEnabled = gc
        }
        if let notif = s.notifications_enabled {
            copy.notificationsEnabled = notif
        }
        if let usePrefs = s.use_preferences_for_personalization {
            copy.usePreferencesForPersonalization = usePrefs
        }

        return copy
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
    case "study":
        return "Study Spots / Cozy Cafés"
    case "free_events":
        return "Free Events & Pop-Ups"
    case "food":
        return "Food Around Campus"
    case "nightlife":
        return "Nightlife"
    case "explore":
        return "Explore All / I'm open to anything"
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

