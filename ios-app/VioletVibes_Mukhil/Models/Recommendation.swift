//
//  Recommendation.swift
//  VioletVibes
//

import Foundation

struct Recommendation: Identifiable, Codable, Sendable {
    let id: Int
    let title: String
    var description: String?
    var distance: String?
    var walkTime: String?
    var lat: Double?
    var lng: Double?
    var popularity: String?
    var image: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, distance, walkTime, lat, lng, popularity, image
        case walk_time, photo_url, rating, address, location, name, distance_text, duration_text
        case place_id, maps_link
    }
    
    init(id: Int, title: String, description: String? = nil, distance: String? = nil, walkTime: String? = nil, lat: Double? = nil, lng: Double? = nil, popularity: String? = nil, image: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.distance = distance
        self.walkTime = walkTime
        self.lat = lat
        self.lng = lng
        self.popularity = popularity
        self.image = image
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle ID - can be from "id" or "place_id"
        if let decodedId = try? container.decodeIfPresent(Int.self, forKey: .id) {
            id = decodedId
        } else if let placeId = try? container.decodeIfPresent(String.self, forKey: .place_id) {
            // Use hash of place_id as ID if it's a string
            id = abs(placeId.hashValue)
        } else {
            id = 0
        }
        
        // Handle both "name" and "title" from API (server uses "name")
        if let name = try? container.decodeIfPresent(String.self, forKey: .name) {
            title = name
        } else if let titleValue = try? container.decodeIfPresent(String.self, forKey: .title) {
            title = titleValue
        } else {
            title = ""
        }
        
        // Handle description/address (server uses "address")
        if let desc = try? container.decodeIfPresent(String.self, forKey: .description) {
            description = desc
        } else {
            description = try? container.decodeIfPresent(String.self, forKey: .address)
        }
        
        // Handle distance (server uses "distance" directly)
        if let dist = try? container.decodeIfPresent(String.self, forKey: .distance) {
            distance = dist
        } else {
            distance = try? container.decodeIfPresent(String.self, forKey: .distance_text)
        }
        
        // Handle walk time (server uses "walk_time")
        if let walk = try? container.decodeIfPresent(String.self, forKey: .walk_time) {
            walkTime = walk
        } else if let walk = try? container.decodeIfPresent(String.self, forKey: .walkTime) {
            walkTime = walk
        } else {
            walkTime = try? container.decodeIfPresent(String.self, forKey: .duration_text)
        }
        
        // Handle location object (server returns {"lat": X, "lng": Y})
        if let locationDict = try? container.decodeIfPresent([String: Double].self, forKey: .location) {
            lat = locationDict["lat"]
            lng = locationDict["lng"]
        } else {
            // Fallback to direct lat/lng fields
            lat = try? container.decodeIfPresent(Double.self, forKey: .lat)
            lng = try? container.decodeIfPresent(Double.self, forKey: .lng)
        }
        
        // Handle popularity/rating (server uses "rating" as a number)
        if let rating = try? container.decodeIfPresent(Double.self, forKey: .rating) {
            popularity = "⭐ \(String(format: "%.1f", rating))"
        } else if let rating = try? container.decodeIfPresent(Int.self, forKey: .rating) {
            popularity = "⭐ \(String(format: "%.1f", Double(rating)))"
        } else {
            popularity = try? container.decodeIfPresent(String.self, forKey: .popularity)
        }
        
        // Handle image (server uses "photo_url")
        if let img = try? container.decodeIfPresent(String.self, forKey: .photo_url) {
            image = img
        } else {
            image = try? container.decodeIfPresent(String.self, forKey: .image)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(distance, forKey: .distance)
        try container.encodeIfPresent(walkTime, forKey: .walkTime)
        try container.encodeIfPresent(lat, forKey: .lat)
        try container.encodeIfPresent(lng, forKey: .lng)
        try container.encodeIfPresent(popularity, forKey: .popularity)
        try container.encodeIfPresent(image, forKey: .image)
    }
}

