//
//  Visit.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/20/25.
//
import Foundation
import SwiftData

@Model
final class Visit {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    
    // Unique park identifier using composite format: {city}:{external_id}
    var parkUniqueID: String = ""
    var parkName: String = ""  // Backup for display if park not found locally
    
    // Relationships - Must be optional for CloudKit compatibility
    var user: User?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        parkUniqueID: String = "",
        parkName: String = "",
        user: User? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.parkUniqueID = parkUniqueID
        self.parkName = parkName
        self.user = user
    }
    
    // Convenience initializer using Park object
    convenience init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        park: Park,
        user: User
    ) {
        self.init(
            id: id,
            timestamp: timestamp,
            parkUniqueID: Visit.generateUniqueID(for: park),
            parkName: park.name,
            user: user
        )
    }
    
    // MARK: - Composite ID Helpers
    
    /// Generates a composite unique ID for a park in format: {city}:{external_id}
    static func generateUniqueID(for park: Park) -> String {
        let cityName = park.city?.name ?? "unknown"
        let externalID = park.propertyID ?? park.id.uuidString
        return "\(cityName):\(externalID)"
    }
    
    /// Parses a composite unique ID into city name and external ID
    func parseUniqueID() -> (cityName: String, externalID: String)? {
        let components = parkUniqueID.components(separatedBy: ":")
        guard components.count == 2 else { return nil }
        return (cityName: components[0], externalID: components[1])
    }
    
    // Helper to find the associated park in the local database
    func findPark(in modelContext: ModelContext) -> Park? {
        guard !parkUniqueID.isEmpty,
              let parsed = parseUniqueID() else {
            return nil
        }
        
        let externalID = parsed.externalID
        let descriptor = FetchDescriptor<Park>(
            predicate: #Predicate<Park> { park in
                park.propertyID == externalID
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
