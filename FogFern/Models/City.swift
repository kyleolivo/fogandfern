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
    var id: UUID
    var name: String
    var displayName: String
    var state: String
    var country: String
    var timezone: String
    var isActive: Bool
    var createdDate: Date
    var lastUpdated: Date
    
    // Geographic boundaries
    var boundaryNorthLat: Double
    var boundarySouthLat: Double
    var boundaryEastLng: Double
    var boundaryWestLng: Double
    
    // Configuration
    var defaultMapZoom: Double
    var centerLatitude: Double
    var centerLongitude: Double
    
    // External data integration
    var openDataURL: String?
    var parksDatasetID: String?
    var facilitiesDatasetID: String?
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Park.city)
    var parks: [Park] = []
    
    init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        state: String,
        country: String,
        timezone: String,
        boundaryNorthLat: Double,
        boundarySouthLat: Double,
        boundaryEastLng: Double,
        boundaryWestLng: Double,
        centerLatitude: Double,
        centerLongitude: Double,
        defaultMapZoom: Double = 12.0,
        openDataURL: String? = nil,
        parksDatasetID: String? = nil,
        facilitiesDatasetID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.state = state
        self.country = country
        self.timezone = timezone
        self.boundaryNorthLat = boundaryNorthLat
        self.boundarySouthLat = boundarySouthLat
        self.boundaryEastLng = boundaryEastLng
        self.boundaryWestLng = boundaryWestLng
        self.centerLatitude = centerLatitude
        self.centerLongitude = centerLongitude
        self.defaultMapZoom = defaultMapZoom
        self.openDataURL = openDataURL
        self.parksDatasetID = parksDatasetID
        self.facilitiesDatasetID = facilitiesDatasetID
        self.isActive = true
        self.createdDate = Date()
        self.lastUpdated = Date()
    }
    
    var centerCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
    }
    
    var boundingBox: (northeast: CLLocationCoordinate2D, southwest: CLLocationCoordinate2D) {
        let northeast = CLLocationCoordinate2D(latitude: boundaryNorthLat, longitude: boundaryEastLng)
        let southwest = CLLocationCoordinate2D(latitude: boundarySouthLat, longitude: boundaryWestLng)
        return (northeast: northeast, southwest: southwest)
    }
}

// MARK: - San Francisco Default
extension City {
    static let sanFrancisco = City(
        name: "san_francisco",
        displayName: "San Francisco",
        state: "California",
        country: "United States",
        timezone: "America/Los_Angeles",
        boundaryNorthLat: 37.812,
        boundarySouthLat: 37.708,
        boundaryEastLng: -122.357,
        boundaryWestLng: -122.515,
        centerLatitude: 37.7749,
        centerLongitude: -122.4194,
        defaultMapZoom: 12.0,
        openDataURL: "https://data.sfgov.org",
        parksDatasetID: "gtr9-ntp6",
        facilitiesDatasetID: "ib5c-xgwu"
    )
}