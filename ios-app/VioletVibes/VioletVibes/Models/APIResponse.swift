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
    let first_name: String?
    let home_address: String?
    let preferences: BackendPreferencesPayload?
    let settings: BackendSettingsPayload?
}

struct AuthResponse: Codable, Sendable {
    let token: String
    let user: AuthUserPayload
}

// MARK: - Dashboard Response

// Free time block structure
struct FreeTimeBlock: Codable, Sendable {
    let start: String  // ISO8601 date string
    let end: String    // ISO8601 date string
}

// Suggestion item for events and places
struct SuggestionItem: Codable, Sendable {
    let name: String?
    let start: String?  // ISO8601 for events
    let location: String?
    let description: String?
    let address: String?
    let maps_link: String?
    let photo_url: String?
}

// Free time suggestion structure
struct FreeTimeSuggestion: Codable, Sendable {
    let should_suggest: Bool
    let type: String  // "event" or "place"
    let suggestion: SuggestionItem
    let message: String
}

struct DashboardAPIResponse: Codable, Sendable {
    let weather: Weather?  // ✅ Already works - Weather model decodes {temp_f, desc, icon}
    let calendar_linked: Bool?
    let next_free: FreeTimeBlock?  // Changed from String?
    let free_time_suggestion: FreeTimeSuggestion?  // Changed from String?
    let quick_recommendations: [String: [Recommendation]]?  // ✅ Already correct
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

// MARK: - User Profile Response

struct UserProfileResponse: Codable, Sendable {
    let first_name: String?
    let home_address: String?
}

// MARK: - Calendar Free Time Responses

struct FreeTimeBlocksResponse: Codable, Sendable {
    let free_blocks: [FreeTimeBlock]
    let error: String?
}

struct NextFreeBlockResponse: Codable, Sendable {
    let status: String?
    let free_block: FreeTimeBlockWithDuration?
    let error: String?
}

struct FreeTimeBlockWithDuration: Codable, Sendable {
    let start: String
    let end: String
    let duration_minutes: Int?
}

struct NextFreeRecommendationResponse: Codable, Sendable {
    let has_free_time: Bool?
    let next_free: FreeTimeBlock?
    let suggestion: SuggestionItem?
    let suggestion_type: String?
    let message: String?
    let error: String?
}

struct FullRecommendationResponse: Codable, Sendable {
    let has_free_time: Bool?
    let next_free: FreeTimeBlock?
    let suggestion: SuggestionItem?
    let suggestion_type: String?
    let message: String?
    let error: String?
}

