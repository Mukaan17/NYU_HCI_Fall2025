//
//  APIResponse.swift
//  VioletVibes
//

import Foundation

struct ChatAPIResponse: Codable {
    let reply: String
    let places: [Recommendation]?
    let vibe: String?
    let weather: Weather?
    let error: String?
}

struct QuickRecsAPIResponse: Codable {
    let category: String
    let places: [Recommendation]
    let error: String?
}

struct DirectionsAPIResponse: Codable {
    let distance_text: String?
    let duration_text: String?
    let maps_link: String?
    let polyline: [[Double]]?
    let error: String?
}

struct EventsAPIResponse: Codable {
    let nyc_permitted: [NYCEvent]
    let error: String?
}

struct NYCEvent: Codable {
    let event_name: String?
    let event_start: String?
    let latitude: Double?
    let longitude: Double?
    let address: String?
}

