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
        if !allPlaces.contains(where: { $0.id == place.id }) {
            allPlaces.append(place)
        }
    }
}

