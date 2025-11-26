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
    
    func setSelectedPlace(_ place: SelectedPlace) {
        selectedPlace = place
    }
    
    func clearSelectedPlace() {
        selectedPlace = nil
    }
}

