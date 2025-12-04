//
//  UserSession.swift
//  VioletVibes
//

import Foundation
import Observation

@Observable
final class UserSession {

    // ============================================================
    // MARK: - STORED PROPERTIES
    // ============================================================
    
    /// JWT token for authenticated requests
    var jwt: String? = nil

    /// Whether the user linked Google Calendar OAuth
    var googleCalendarLinked: Bool = false

    /// User preferences stored locally + synced with backend
    var preferences: UserPreferences = UserPreferences()

    /// Raw backend settings payload (if you need it in views)
    var settings: BackendSettingsPayload? = nil


    // ============================================================
    // MARK: - APPLY AUTH RESULT (login/signup)
    // ============================================================
    @MainActor
    func applyAuthResult(
        token: String,
        backendPrefs: BackendPreferencesPayload?,
        backendSettings: BackendSettingsPayload?,
        storage: StorageService
    ) async {

        // 1) Save JWT
        self.jwt = token

        // 2) Start from whatever prefs we already had on disk
        let existingPrefs = await storage.userPreferences

        // 3) Merge backend /preferences into UserPreferences
        let fromBackend = UserPreferences.fromBackendPreferencesPayload(
            backendPrefs,
            existing: existingPrefs
        )

        // 4) Apply backend /settings flags (calendar, notifications) onto prefs
        let merged = UserPreferences.mergedWithSettings(
            fromBackend,
            backendSettings: backendSettings
        )

        self.preferences = merged
        await storage.saveUserPreferences(merged)

        // 5) Keep a copy of backend settings + calendar link flag
        self.settings = backendSettings

        if let s = backendSettings, let linked = s.google_calendar_enabled {
            self.googleCalendarLinked = linked
        }
        // 6) SAVE SESSION (jwt + googleCalendarLinked)
        await storage.saveUserSession(self)

    }


    // ============================================================
    // MARK: - UPDATE CALENDAR LINK STATUS
    // ============================================================
    /// Call this after the Google OAuth callback succeeds (e.g. via deep link)
    func markCalendarLinked(_ storage: StorageService) async {
        googleCalendarLinked = true

        // Also mirror this into preferences.googleCalendarEnabled
        var prefs = preferences
        prefs.googleCalendarEnabled = true
        preferences = prefs

        await storage.saveUserPreferences(prefs)
    }
}
