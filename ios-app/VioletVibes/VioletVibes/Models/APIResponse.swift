//
//  APIResponse.swift
//  VioletVibes
//

import Foundation

struct ChatAPIResponse: Codable, Sendable {
    let reply: String?
    let places: [Recommendation]?
    let debug_vibe: String?
    let latency: Double?
    let weather: Weather?
    let error: String?

    var replyText: String {
        reply ?? error ?? "I'm having trouble responding right now."
    }
}

struct QuickRecsAPIResponse: Codable, Sendable {
    let category: String
    let places: [Recommendation]
    let error: String?
}

struct StepInstruction: Codable, Sendable, Identifiable {
    let id = UUID()
    let instruction: String
    let distance: String
    let duration: String
}

struct DirectionsAPIResponse: Codable, Sendable {
    let distance_text: String?
    let duration_text: String?
    let maps_link: String?
    let polyline: [[Double]]?
    let steps: [StepInstruction]?
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

struct Weather: Codable, Sendable {
    let desc: String
    let icon: String
    let temp_f: Double

    var emoji: String {
        switch icon {
        case "01d": return "☀️"
        case "01n": return "🌕"
        case "02d": return "🌤️"
        case "02n": return "🌥️"
        case "03d", "03n": return "☁️"
        case "04d", "04n": return "☁️"
        case "09d", "09n": return "🌧️"
        case "10d": return "🌦️"
        case "10n": return "🌧️"
        case "11d", "11n": return "⛈️"
        case "13d", "13n": return "❄️"
        case "50d", "50n": return "🌫️"
        default:
            return "🌡️"
        }
    }
    var tempF: Int { Int(temp_f) }
}
