//
//  SelectedPlace.swift
//  VioletVibes
//

import Foundation
import CoreLocation

struct SelectedPlace: Identifiable, Codable, Sendable, Equatable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    var walkTime: String?
    var distance: String?
    var address: String?
    var image: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    enum CodingKeys: String, CodingKey {
        case name, latitude, longitude, walkTime, distance, address, image
    }
    
    init(name: String, latitude: Double, longitude: Double, walkTime: String? = nil, distance: String? = nil, address: String? = nil, image: String? = nil) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.walkTime = walkTime
        self.distance = distance
        self.address = address
        self.image = image
    }
    
    static func == (lhs: SelectedPlace, rhs: SelectedPlace) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude &&
        lhs.walkTime == rhs.walkTime &&
        lhs.distance == rhs.distance &&
        lhs.address == rhs.address &&
        lhs.image == rhs.image
    }
}

