//
//  Item.swift
//  VioletVibes
//
//  Created by Mukhil Sundararaj on 11/20/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
