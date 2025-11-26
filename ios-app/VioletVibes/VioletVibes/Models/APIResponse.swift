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

