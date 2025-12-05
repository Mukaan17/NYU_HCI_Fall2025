//
//  APIResponse.swift
//  VioletVibes
//

import Foundation

struct ChatAPIResponse: Codable, Sendable {
    let reply: String?
    let places: [Recommendation]?
    let vibe: String?
    let weather: Weather?
    let error: String?
    
    // Computed property to get reply or fallback
    var replyText: String {
        reply ?? error ?? "I'm having trouble responding right now."
    }
    
    // Custom initializer for fallback cases
    init(reply: String?, places: [Recommendation]?, vibe: String?, weather: Weather?, error: String?) {
        self.reply = reply
        self.places = places
        self.vibe = vibe
        self.weather = weather
        self.error = error
    }
}

struct QuickRecsAPIResponse: Codable, Sendable {
    let category: String
    let places: [Recommendation]
    let error: String?
}

struct DirectionsAPIResponse: Codable, Sendable {
    let distance_text: String?
    let duration_text: String?
    let maps_link: String?
    let polyline: [[Double]]?
    let mode: String? // "walking" or "transit" - indicates which mode was chosen
    let error: String?
}

struct EventsAPIResponse: Codable, Sendable {
    let nyc_permitted: [NYCEvent]
    let error: String?
}

struct NYCEvent: Codable, Sendable {
    let event_name: String?
    let event_start: String?
    let latitude: Double?
    let longitude: Double?
    let address: String?
}

// MARK: - Authentication Models
// Note: BackendBudgetPayload, BackendPreferencesPayload, and BackendSettingsPayload
// are defined in UserPreferences.swift to avoid duplication

struct AuthUserPayload: Codable, Sendable {
    let id: Int
    let email: String
    let preferences: BackendPreferencesPayload?
    let settings: BackendSettingsPayload?
}

struct AuthResponse: Codable, Sendable {
    let token: String
    let user: AuthUserPayload
}

// MARK: - Dashboard Response

struct DashboardAPIResponse: Codable, Sendable {
    let weather: Weather?
    let calendar_linked: Bool?
    let next_free: String?
    let free_time_suggestion: String?
    let quick_recommendations: [String: [Recommendation]]?
}

// MARK: - Notification Check Response

struct NotificationCheckResponse: Codable, Sendable {
    let notifications: [NotificationMatch]
    let error: String?
}

struct NotificationMatch: Codable, Sendable {
    let free_time: FreeTimeSlot
    let events: [EventMatch]
}

struct FreeTimeSlot: Codable, Sendable {
    let start: String
    let end: String
    let duration_minutes: Double
}

struct EventMatch: Codable, Sendable {
    let title: String?
    let start: String?
    let description: String?
    let location: String?
    let type: String?
}

// MARK: - Calendar Events Response

struct CalendarEventsResponse: Codable, Sendable {
    let events: [CalendarEvent]
    let error: String?
}

struct CalendarEvent: Codable, Sendable {
    let id: String?
    let name: String?
    let description: String?
    let start: String?
    let end: String?
    let location: String?
}

