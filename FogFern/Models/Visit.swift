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
    
    // CloudKit-optimized park reference using stable SF Parks Property ID
    var parkSFParksPropertyID: String = ""
    var parkName: String = ""  // Backup for display if park not found locally
    
    // Relationships - Must be optional for CloudKit compatibility
    var user: User?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        parkSFParksPropertyID: String = "",
        parkName: String = "",
        user: User? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.parkSFParksPropertyID = parkSFParksPropertyID
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
            parkSFParksPropertyID: park.sfParksPropertyID ?? "",
            parkName: park.name,
            user: user
        )
    }
    
    // Helper to find the associated park in the local database
    func findPark(in modelContext: ModelContext) -> Park? {
        let propertyID = self.parkSFParksPropertyID
        
        // Don't search if the property ID is empty or nil
        guard !propertyID.isEmpty else {
            return nil
        }
        
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
