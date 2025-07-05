//
//  SchemaVersions.swift
//  FogFern
//
//  SwiftData CloudKit Schema Versioning System
//  Handles data model evolution and migration for CloudKit-synced models only
//  Note: Park and City models are local-only and don't require versioning
//

import Foundation
import SwiftData
import CoreLocation

// MARK: - CloudKit Schema Version Enum
enum CloudKitSchemaVersion: Int, CaseIterable {
    case v1 = 1  // Initial release with CloudKit-optimized user data models
    case v2 = 2  // Future: Add photo attachments to visits
    case v3 = 3  // Future: Add user preferences and settings
    case v4 = 4  // Future: Add social features
    
    var version: Schema.Version {
        Schema.Version(rawValue, 0, 0)
    }
    
    static var current: CloudKitSchemaVersion {
        return .v1
    }
}

// MARK: - CloudKit Schema V1 (Current) - User Data Only
enum CloudKitSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Visit.self, User.self]  // Only user-generated data syncs to CloudKit
    }
    
    @Model
    final class Visit {
        var id: UUID
        var timestamp: Date
        
        // Unique park identifier using composite format: {city}:{external_id}
        var parkUniqueID: String
        var parkName: String  // Backup for display if park not found locally
        
        // Visit status - allows toggling instead of delete/create cycles
        var isActive: Bool
        
        // Relationships
        var user: User
        
        init(
            id: UUID = UUID(),
            timestamp: Date = Date(),
            parkUniqueID: String,
            parkName: String,
            isActive: Bool = true,
            user: User
        ) {
            self.id = id
            self.timestamp = timestamp
            self.parkUniqueID = parkUniqueID
            self.parkName = parkName
            self.isActive = isActive
            self.user = user
        }
        
        // Note: Convenience initializer with Park object is available in the main Visit model
        // but not in CloudKit schema versions since Park is local-only
        
        /// Parses a composite unique ID into city name and external ID
        func parseUniqueID() -> (cityName: String, externalID: String)? {
            let components = parkUniqueID.components(separatedBy: ":")
            guard components.count == 2 else { return nil }
            return (cityName: components[0], externalID: components[1])
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
}

// MARK: - Future CloudKit Schema V2 (Example)
enum CloudKitSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Visit.self, User.self]  // Only user-generated data syncs to CloudKit
    }
    
    @Model
    final class Visit {
        var id: UUID
        var timestamp: Date
        
        // CloudKit-optimized park reference
        var parkUniqueID: String
        var parkName: String
        
        // Visit status - carried over from V1
        var isActive: Bool
        
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
            parkUniqueID: String,
            parkName: String,
            isActive: Bool = true,
            photoURLs: [String] = [],
            weather: String? = nil,
            rating: Int? = nil,
            user: User
        ) {
            self.id = id
            self.timestamp = timestamp
            self.parkUniqueID = parkUniqueID
            self.parkName = parkName
            self.isActive = isActive
            self.photoURLs = photoURLs
            self.weather = weather
            self.rating = rating
            self.user = user
        }
        
        /// Parses a composite unique ID into city name and external ID
        func parseUniqueID() -> (cityName: String, externalID: String)? {
            let components = parkUniqueID.components(separatedBy: ":")
            guard components.count == 2 else { return nil }
            return (cityName: components[0], externalID: components[1])
        }
    }
    
    // User and other models would remain the same or have their own additions
}

// MARK: - CloudKit Schema Factory
struct CloudKitSchemaFactory {
    /// Creates CloudKit schema for user data only (Visit, User)
    /// Park and City models are local-only and don't need versioning
    static func createCloudKitSchema(for version: CloudKitSchemaVersion) -> Schema {
        switch version {
        case .v1:
            return Schema([
                CloudKitSchemaV1.Visit.self,
                CloudKitSchemaV1.User.self
            ], version: version.version)
        case .v2:
            return Schema([
                CloudKitSchemaV2.Visit.self,
                CloudKitSchemaV1.User.self  // Reuse V1 if unchanged
            ], version: version.version)
        case .v3, .v4:
            // Future versions - return current for now
            return Schema([
                CloudKitSchemaV1.Visit.self,
                CloudKitSchemaV1.User.self
            ], version: CloudKitSchemaVersion.v1.version)
        }
    }
    
    /// Creates local-only schema for reference data (Park, City)
    /// These models are loaded from JSON and don't require CloudKit sync
    static func createLocalSchema() -> Schema {
        return Schema([Park.self, City.self])
    }
}
