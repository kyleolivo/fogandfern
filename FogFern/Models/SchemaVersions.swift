//
//  SchemaVersions.swift
//  FogFern
//
//  SwiftData Schema Versioning System
//  Handles data model evolution and migration
//

import Foundation
import SwiftData
import CoreLocation

// MARK: - Schema Version Enum
enum SchemaVersion: Int, CaseIterable {
    case v1 = 1  // Initial release with CloudKit-optimized models
    case v2 = 2  // Future: Add photo attachments to visits
    case v3 = 3  // Future: Add user preferences and settings
    case v4 = 4  // Future: Add social features
    
    var version: Schema.Version {
        Schema.Version(rawValue, 0, 0)
    }
    
    static var current: SchemaVersion {
        return .v1
    }
}

// MARK: - Version 1 Schema (Current)
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Visit.self, User.self, Park.self, City.self]
    }
    
    @Model
    final class Visit {
        var id: UUID
        var timestamp: Date
        var journalEntry: String?
        
        // CloudKit-optimized park reference using stable SF Parks Property ID
        var parkSFParksPropertyID: String
        var parkName: String  // Backup for display if park not found locally
        
        // Relationships
        var user: User
        
        init(
            id: UUID = UUID(),
            timestamp: Date = Date(),
            journalEntry: String? = nil,
            parkSFParksPropertyID: String,
            parkName: String,
            user: User
        ) {
            self.id = id
            self.timestamp = timestamp
            self.journalEntry = journalEntry
            self.parkSFParksPropertyID = parkSFParksPropertyID
            self.parkName = parkName
            self.user = user
        }
        
        // Convenience initializer using Park object
        convenience init(
            id: UUID = UUID(),
            timestamp: Date = Date(),
            journalEntry: String? = nil,
            park: Park,
            user: User
        ) {
            self.init(
                id: id,
                timestamp: timestamp,
                journalEntry: journalEntry,
                parkSFParksPropertyID: park.sfParksPropertyID ?? "",
                parkName: park.name,
                user: user
            )
        }
        
        // Helper to find the associated park in the local database
        func findPark(in modelContext: ModelContext) -> Park? {
            let propertyID = self.parkSFParksPropertyID
            let descriptor = FetchDescriptor<Park>(
                predicate: #Predicate<Park> { park in
                    park.sfParksPropertyID == propertyID
                }
            )
            
            do {
                let parks = try modelContext.fetch(descriptor)
                return parks.first
            } catch {
                // Error finding park for visit: \(error)
                return nil
            }
        }
    }
    
    @Model
    final class User {
        var id: UUID
        var createdDate: Date
        
        // Relationships
        @Relationship(deleteRule: .cascade, inverse: \Visit.user)
        var visits: [Visit] = []
        
        init(id: UUID = UUID()) {
            self.id = id
            self.createdDate = Date()
        }
    }
    
    @Model
    final class Park {
        var id: UUID
        var name: String
        var shortDescription: String
        var fullDescription: String
        var category: ParkCategory
        var size: ParkSize
        
        // Location
        var latitude: Double
        var longitude: Double
        var address: String
        var neighborhood: String?
        var zipCode: String?
        
        // Physical characteristics
        var acreage: Double
        
        // SF Parks API Integration
        var sfParksPropertyID: String?
        
        // Status and metadata
        var isActive: Bool
        var createdDate: Date
        var lastUpdated: Date
        
        // Relationships
        var city: City
        
        init(
            id: UUID = UUID(),
            name: String,
            shortDescription: String,
            fullDescription: String,
            category: ParkCategory,
            latitude: Double,
            longitude: Double,
            address: String,
            neighborhood: String? = nil,
            zipCode: String? = nil,
            acreage: Double,
            sfParksPropertyID: String? = nil,
            city: City
        ) {
            self.id = id
            self.name = name
            self.shortDescription = shortDescription
            self.fullDescription = fullDescription
            self.category = category
            self.size = ParkSize.categorize(acres: acreage)
            self.latitude = latitude
            self.longitude = longitude
            self.address = address
            self.neighborhood = neighborhood
            self.zipCode = zipCode
            self.acreage = acreage
            self.sfParksPropertyID = sfParksPropertyID
            self.city = city
            self.isActive = true
            self.createdDate = Date()
            self.lastUpdated = Date()
        }
        
        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        var location: CLLocation {
            CLLocation(latitude: latitude, longitude: longitude)
        }
        
        var formattedAcreage: String {
            if acreage < 1.0 {
                return String(format: "%.1f acres", acreage)
            } else {
                return String(format: "%.0f acres", acreage)
            }
        }
        
        var imageName: String {
            return name
                .lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: "&", with: "and")
                .replacingOccurrences(of: "'", with: "")
                .replacingOccurrences(of: ".", with: "")
        }
        
        func distance(from location: CLLocation) -> CLLocationDistance {
            self.location.distance(from: location)
        }
        
        func formattedDistance(from location: CLLocation) -> String {
            let distance = distance(from: location)
            let distanceInMiles = distance * 0.000621371 // Convert meters to miles
            
            if distanceInMiles < 0.1 {
                return "< 0.1 mi"
            } else if distanceInMiles < 1.0 {
                return String(format: "%.1f mi", distanceInMiles)
            } else {
                return String(format: "%.0f mi", distanceInMiles)
            }
        }
    }
    
    @Model
    final class City {
        var id: UUID
        var name: String
        var displayName: String
        var createdDate: Date
        var lastUpdated: Date
        
        // Geographic center
        var centerLatitude: Double
        var centerLongitude: Double
        
        // Relationships
        @Relationship(deleteRule: .cascade, inverse: \Park.city)
        var parks: [Park] = []
        
        init(
            id: UUID = UUID(),
            name: String,
            displayName: String,
            centerLatitude: Double,
            centerLongitude: Double
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
}

// MARK: - Future Version 2 Schema (Example)
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Visit.self, User.self, Park.self, City.self]
    }
    
    @Model
    final class Visit {
        var id: UUID
        var timestamp: Date
        var journalEntry: String?
        
        // CloudKit-optimized park reference
        var parkSFParksPropertyID: String
        var parkName: String
        
        // NEW in V2: Photo attachments
        var photoURLs: [String] = []  // CloudKit asset references
        var weather: String?          // Weather conditions during visit
        var rating: Int?              // User rating 1-5
        
        // Relationships
        var user: User
        
        // Migration note: Initialize new fields with defaults
        init(
            id: UUID = UUID(),
            timestamp: Date = Date(),
            journalEntry: String? = nil,
            parkSFParksPropertyID: String,
            parkName: String,
            photoURLs: [String] = [],
            weather: String? = nil,
            rating: Int? = nil,
            user: User
        ) {
            self.id = id
            self.timestamp = timestamp
            self.journalEntry = journalEntry
            self.parkSFParksPropertyID = parkSFParksPropertyID
            self.parkName = parkName
            self.photoURLs = photoURLs
            self.weather = weather
            self.rating = rating
            self.user = user
        }
    }
    
    // User and other models would remain the same or have their own additions
}

// MARK: - Schema Factory
struct SchemaFactory {
    static func createSchema(for version: SchemaVersion) -> Schema {
        switch version {
        case .v1:
            return Schema([
                SchemaV1.Visit.self,
                SchemaV1.User.self,
                SchemaV1.Park.self,
                SchemaV1.City.self
            ], version: version.version)
        case .v2:
            return Schema([
                SchemaV2.Visit.self,
                SchemaV1.User.self,  // Reuse V1 if unchanged
                SchemaV1.Park.self,   // Reuse V1 if unchanged
                SchemaV1.City.self    // Reuse V1 if unchanged
            ], version: version.version)
        case .v3, .v4:
            // Future versions - return current for now
            return Schema([
                SchemaV1.Visit.self,
                SchemaV1.User.self,
                SchemaV1.Park.self,
                SchemaV1.City.self
            ], version: SchemaVersion.v1.version)
        }
    }
}
