//
//  Recommendation.swift
//  VioletVibes
//

import Foundation

struct Recommendation: Identifiable, Codable, Sendable, Hashable {

    // MARK: - Core fields

    let id: String

    let title: String
    var description: String?
    var distance: String?
    var walkTime: String?
    var lat: Double?
    var lng: Double?

    /// Human-readable label like "⭐ 4.7" or "Busy"
    var popularity: String?

    /// Extra backend metadata
    var busyness: Double?
    var rating: Double?
    var score: Double?
    var mapsLink: String?
    var type: String?
    var source: String?

    /// URL string for an image / photo
    var image: String?

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id

        case title
        case description
        case distance
        case walkTime

        case name
        case address
        case distance_text
        case duration_text
        case walk_time

        case lat
        case lng
        case location

        case popularity
        case rating
        case busyness
        case score
        case maps_link
        case type
        case source

        case image
        case photo_url

        case place_id
    }

    // MARK: - Convenience init for manual construction (Chat / Sample)

    init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        distance: String? = nil,
        walkTime: String? = nil,
        lat: Double? = nil,
        lng: Double? = nil,
        popularity: String? = nil,
        image: String? = nil,
        busyness: Double? = nil,
        rating: Double? = nil,
        score: Double? = nil,
        mapsLink: String? = nil,
        type: String? = nil,
        source: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.distance = distance
        self.walkTime = walkTime
        self.lat = lat
        self.lng = lng
        self.popularity = popularity
        self.image = image
        self.busyness = busyness
        self.rating = rating
        self.score = score
        self.mapsLink = mapsLink
        self.type = type
        self.source = source
    }

    // MARK: - Decoding from backend

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // ----- title / name -----
        if let name = try? container.decodeIfPresent(String.self, forKey: .name) {
            title = name
        } else if let t = try? container.decodeIfPresent(String.self, forKey: .title) {
            title = t
        } else {
            title = "Unknown"
        }

        // ----- description (address or description) -----
        if let desc = try? container.decodeIfPresent(String.self, forKey: .description) {
            description = desc
        } else {
            description = try? container.decodeIfPresent(String.self, forKey: .address)
        }

        // ----- distance -----
        if let d = try? container.decodeIfPresent(String.self, forKey: .distance) {
            distance = d
        } else {
            distance = try? container.decodeIfPresent(String.self, forKey: .distance_text)
        }

        // ----- walk time -----
        if let wt = try? container.decodeIfPresent(String.self, forKey: .walk_time) {
            walkTime = wt
        } else {
            walkTime = try? container.decodeIfPresent(String.self, forKey: .duration_text)
        }

        // ----- location -----
        if let loc = try? container.decodeIfPresent([String: Double].self, forKey: .location) {
            lat = loc["lat"]
            lng = loc["lng"]
        } else {
            lat = try? container.decodeIfPresent(Double.self, forKey: .lat)
            lng = try? container.decodeIfPresent(Double.self, forKey: .lng)
        }

        // ----- rating -----
        if let rDouble = try? container.decodeIfPresent(Double.self, forKey: .rating) {
            rating = rDouble
        } else if let rInt = try? container.decodeIfPresent(Int.self, forKey: .rating) {
            rating = Double(rInt)
        } else {
            rating = nil
        }

        // ----- popularity label -----
        if let pop = try? container.decodeIfPresent(String.self, forKey: .popularity) {
            popularity = pop
        } else if let r = rating {
            popularity = String(format: "⭐ %.1f", r)
        } else {
            popularity = nil
        }

        // ----- image / photo -----
        if let photo = try? container.decodeIfPresent(String.self, forKey: .photo_url) {
            image = photo
        } else {
            image = try? container.decodeIfPresent(String.self, forKey: .image)
        }

        // ----- extra backend fields -----
        busyness = try? container.decodeIfPresent(Double.self, forKey: .busyness)
        score = try? container.decodeIfPresent(Double.self, forKey: .score)
        mapsLink = try? container.decodeIfPresent(String.self, forKey: .maps_link)
        type = try? container.decodeIfPresent(String.self, forKey: .type)
        source = try? container.decodeIfPresent(String.self, forKey: .source)

        // ----- id (backend id, place_id, or derived fallback) -----
        let backendID = try? container.decodeIfPresent(String.self, forKey: .id)
        let placeID = try? container.decodeIfPresent(String.self, forKey: .place_id)

        if let backendID, !backendID.isEmpty {
            id = backendID
        } else if let placeID, !placeID.isEmpty {
            id = placeID
        } else {
            let t = title.replacingOccurrences(of: " ", with: "_")
            let la = lat.map { String($0) } ?? "0"
            let lo = lng.map { String($0) } ?? "0"
            id = "\(t)_\(la)_\(lo)"
        }
    }

    // MARK: - Encoding

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

        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encodeIfPresent(busyness, forKey: .busyness)
        try container.encodeIfPresent(score, forKey: .score)

        try container.encodeIfPresent(mapsLink, forKey: .maps_link)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(source, forKey: .source)
    }
}
