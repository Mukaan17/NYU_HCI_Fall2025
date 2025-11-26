//
//  PolylineDecoder.swift
//  VioletVibes
//

import Foundation
import CoreLocation

class PolylineDecoder {
    static func decode(_ encodedPolyline: String) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        var index = encodedPolyline.startIndex
        var lat = 0.0
        var lng = 0.0
        
        while index < encodedPolyline.endIndex {
            var shift = 0
            var result = 0
            var byte: UInt8 = 0
            
            repeat {
                byte = encodedPolyline[index].asciiValue! - 63
                result |= Int((byte & 0x1F) << shift)
                shift += 5
                index = encodedPolyline.index(after: index)
            } while byte >= 0x20
            
            let deltaLat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1)
            lat += Double(deltaLat)
            
            shift = 0
            result = 0
            
            repeat {
                byte = encodedPolyline[index].asciiValue! - 63
                result |= Int((byte & 0x1F) << shift)
                shift += 5
                index = encodedPolyline.index(after: index)
            } while byte >= 0x20
            
            let deltaLng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1)
            lng += Double(deltaLng)
            
            coordinates.append(CLLocationCoordinate2D(latitude: lat / 1e5, longitude: lng / 1e5))
        }
        
        return coordinates
    }
}

