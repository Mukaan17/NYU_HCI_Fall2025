//
//  Recommendation.swift
//  VioletVibes
//

import Foundation

struct Recommendation: Identifiable, Codable {
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
        case walk_time, photo_url, rating, address, location
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
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        
        // Handle both "name" and "title" from API
        if let name = try? container.decode(String.self, forKey: .title) {
            title = name
        } else if let name = try? container.decode(String.self, forKey: CodingKeys(stringValue: "name")!) {
            title = name
        } else {
            title = ""
        }
        
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? 
                     try container.decodeIfPresent(String.self, forKey: .address)
        distance = try container.decodeIfPresent(String.self, forKey: .distance) ?? 
                  try container.decodeIfPresent(String.self, forKey: CodingKeys(stringValue: "distance_text")!)
        walkTime = try container.decodeIfPresent(String.self, forKey: .walkTime) ?? 
                  try container.decodeIfPresent(String.self, forKey: .walk_time) ??
                  try container.decodeIfPresent(String.self, forKey: CodingKeys(stringValue: "duration_text")!)
        
        // Handle location object
        if let locationDict = try? container.decodeIfPresent([String: Double].self, forKey: .location) {
            lat = locationDict["lat"]
            lng = locationDict["lng"]
        } else {
            lat = try container.decodeIfPresent(Double.self, forKey: .lat)
            lng = try container.decodeIfPresent(Double.self, forKey: .lng)
        }
        
        // Handle popularity/rating
        if let rating = try? container.decodeIfPresent(Double.self, forKey: CodingKeys(stringValue: "rating")!) {
            popularity = "⭐ \(String(format: "%.1f", rating))"
        } else {
            popularity = try container.decodeIfPresent(String.self, forKey: .popularity)
        }
        
        image = try container.decodeIfPresent(String.self, forKey: .image) ?? 
               try container.decodeIfPresent(String.self, forKey: .photo_url)
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

