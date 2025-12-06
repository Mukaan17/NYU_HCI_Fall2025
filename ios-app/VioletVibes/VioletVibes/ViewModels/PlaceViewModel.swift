//
//  PlaceViewModel.swift
//  VioletVibes
//

import Foundation
import SwiftUI
import Observation

@Observable
final class PlaceViewModel {
    var selectedPlace: SelectedPlace?
    var allPlaces: [SelectedPlace] = []
    var showHomeOnly: Bool = false // When true, only show home pin on map
    
    func setSelectedPlace(_ place: SelectedPlace) {
        selectedPlace = place
    }
    
    func clearSelectedPlace() {
        selectedPlace = nil
    }
    
    func setAllPlaces(_ places: [SelectedPlace]) {
        allPlaces = places
    }
    
    func addPlace(_ place: SelectedPlace) {
        // Check for duplicates by name and coordinates (since ID is UUID and always unique)
        let isDuplicate = allPlaces.contains { existingPlace in
            existingPlace.name == place.name &&
            abs(existingPlace.latitude - place.latitude) < 0.0001 &&
            abs(existingPlace.longitude - place.longitude) < 0.0001
        }
        if !isDuplicate {
            allPlaces.append(place)
        }
    }
    
    func setHomeOnlyMode(_ enabled: Bool) {
        showHomeOnly = enabled
    }
}

