//
//  Item.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/19/25.
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
