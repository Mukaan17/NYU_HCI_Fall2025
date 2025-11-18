//
//  PlaceViewModel.swift
//  VioletVibes
//

import Foundation
import SwiftUI

class PlaceViewModel: ObservableObject {
    @Published var selectedPlace: SelectedPlace?
    
    func setSelectedPlace(_ place: SelectedPlace) {
        selectedPlace = place
    }
    
    func clearSelectedPlace() {
        selectedPlace = nil
    }
}

