//
//  City.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/20/25.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class City {
    var id: UUID = UUID()
    var name: String = ""
    var displayName: String = ""
    var createdDate: Date = Date()
    var lastUpdated: Date = Date()
    
    // Geographic center - Default to San Francisco coordinates
    var centerLatitude: Double = 37.7749
    var centerLongitude: Double = -122.4194
    
    // Relationships - Optional for CloudKit compatibility
    @Relationship(deleteRule: .cascade, inverse: \Park.city)
    var parks: [Park]? = []
    
    init(
        id: UUID = UUID(),
        name: String = "",
        displayName: String = "",
        centerLatitude: Double = 37.7749,
        centerLongitude: Double = -122.4194
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.centerLatitude = centerLatitude
        self.centerLongitude = centerLongitude
        self.createdDate = Date()
        self.lastUpdated = Date()
    }
    
    var centerCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
    }
}

// MARK: - San Francisco Default
extension City {
    static let sanFrancisco = City(
        name: "san_francisco",
        displayName: "San Francisco",
        centerLatitude: 37.7749,
        centerLongitude: -122.4194
    )
}
