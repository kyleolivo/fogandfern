//
//  ParkDataLoader.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/20/25.
//

import Foundation
import SwiftData

struct ParkDataLoader {
    
    // MARK: - Data Structures
    
    struct ParkData: Codable {
        let name: String
        let shortDescription: String
        let fullDescription: String
        let category: String
        let latitude: Double
        let longitude: Double
        let address: String
        let neighborhood: String?
        let acreage: Double
        let sfParksObjectID: Int?
        let sfParksPropertyID: String?
    }
    
    struct ParksContainer: Codable {
        let version: String
        let parks: [ParkData]
        let generatedDate: String
    }
    
    
    
    // MARK: - Loading Functions
    
    static func loadParks(into modelContext: ModelContext, for city: City) throws {
        // Load parks data
        guard let parksURL = Bundle.main.url(forResource: "SFParks", withExtension: "json") else {
            throw ParkDataLoaderError.fileNotFound
        }
        
        let parksData = try Data(contentsOf: parksURL)
        let container = try JSONDecoder().decode(ParksContainer.self, from: parksData)
        
        // Check existing parks using SF Parks IDs instead of names
        let existingParks = try modelContext.fetch(FetchDescriptor<Park>())
        
        // Build a map of existing parks by SF Parks Property ID for updating
        let existingParksMap: [String: Park] = Dictionary(
            existingParks.compactMap { park in
                guard let propertyID = park.sfParksPropertyID else { return nil }
                return (propertyID, park)
            },
            uniquingKeysWith: { first, _ in first }
        )
        
        // Check if we need to update based on version
        let storedVersion = UserDefaults.standard.string(forKey: "ParksDataVersion")
        let needsUpdate = storedVersion != container.version
        
        // Check for version mismatch to trigger cleanup only when needed
        // Check for duplicate parks that may have been synced from CloudKit
        let existingBySFID = Dictionary(grouping: existingParks) { $0.sfParksPropertyID }
        let cloudKitDuplicates = existingBySFID.filter { $0.value.count > 1 }
        
        // If we have the expected number of parks and same version, don't reload
        if existingParks.count == container.parks.count && 
           existingParks.count > 0 && 
           !needsUpdate {
                return
        }
        
        // Get or create city in this context first
        let cityDescriptor = FetchDescriptor<City>(
            predicate: #Predicate<City> { city in
                city.name == "san_francisco"
            }
        )
        let existingCities = try modelContext.fetch(cityDescriptor)
        let contextCity: City
        
        if let existingCity = existingCities.first {
            contextCity = existingCity
        } else {
            // Create a new city directly in this context
            contextCity = City(
                id: UUID(),
                name: "san_francisco",
                displayName: "San Francisco",
                centerLatitude: 37.7749,
                centerLongitude: -122.4194
            )
            modelContext.insert(contextCity)
        }
        
        // Check for duplicate parks and clean them up
        let existingNames = existingParks.map { $0.name }
        let uniqueNames = Set(existingNames)
        let hasDuplicates = uniqueNames.count != existingParks.count
        
        
        // Clean up if we have duplicates or wrong count, including CloudKit duplicates
        let hasCloudKitDuplicates = !cloudKitDuplicates.isEmpty
        let shouldCleanup = hasDuplicates || existingParks.count != container.parks.count || hasCloudKitDuplicates
        
        if shouldCleanup {
            if hasCloudKitDuplicates {
                // For CloudKit duplicates, keep only one record per sfParksPropertyID
                var parksToDelete: [Park] = []
                for (_, duplicateParts) in cloudKitDuplicates {
                    // Keep the most recent one, delete the rest
                    let sorted = duplicateParts.sorted { $0.lastUpdated > $1.lastUpdated }
                    parksToDelete.append(contentsOf: sorted.dropFirst())
                }
                
                for park in parksToDelete {
                    modelContext.delete(park)
                }
                try modelContext.save()
            } else {
                // Delete all existing parks and reload fresh data
                for park in existingParks {
                    modelContext.delete(park)
                }
                try modelContext.save()
                
                // Insert fresh parks
                for parkData in container.parks {
                    let park = try createPark(from: parkData, for: contextCity)
                    modelContext.insert(park)
                }
            }
            
            // Save new data
            UserDefaults.standard.set(container.version, forKey: "ParksDataVersion")
            try modelContext.save()
            
            return
        }
        
        // Track which parks we've seen in the new data
        var seenPropertyIDs = Set<String>()
        
        for parkData in container.parks {
            guard let propertyID = parkData.sfParksPropertyID else {
                // Skip parks without property IDs as they can't be reliably tracked
                print("Warning: Park '\(parkData.name)' has no sfParksPropertyID")
                continue
            }
            
            seenPropertyIDs.insert(propertyID)
            
            if let existingPark = existingParksMap[propertyID] {
                // Update existing park with new data (preserving visits)
                try updatePark(existingPark, with: parkData, city: contextCity)
            } else {
                // This is a new park, create it
                let park = try createPark(from: parkData, for: contextCity)
                modelContext.insert(park)
            }
        }
        
        // Mark parks as removed if they're no longer in the data
        // (but don't delete them to preserve visit history)
        for park in existingParks {
            if let propertyID = park.sfParksPropertyID,
               !seenPropertyIDs.contains(propertyID) {
                // Mark as removed or inactive (would need to add this property)
                print("Warning: Park '\(park.name)' is no longer in the data but has been preserved")
            }
        }
        
        // Save the new version
        UserDefaults.standard.set(container.version, forKey: "ParksDataVersion")
        
        try modelContext.save()
    }
    
    // MARK: - Versioning Functions
    
    private static func needsDataUpdate(bundledVersion: String) -> Bool {
        let currentVersion = UserDefaults.standard.string(forKey: "ParksDataVersion")
        return currentVersion != bundledVersion
    }
    
    private static func clearExistingParks(from modelContext: ModelContext) {
        do {
            // Delete parks first to clear the relationships
            let parkDescriptor = FetchDescriptor<Park>()
            let existingParks = try modelContext.fetch(parkDescriptor)
            
            for park in existingParks {
                modelContext.delete(park)
            }
            
            // Save after deleting parks to clear relationships
            try modelContext.save()
            
            // Now safely delete cities
            let cityDescriptor = FetchDescriptor<City>()
            let existingCities = try modelContext.fetch(cityDescriptor)
            
            for city in existingCities {
                modelContext.delete(city)
            }
            
            try modelContext.save()
        } catch {
            // Failed to clear existing data
        }
    }
    
    private static func updatePark(_ park: Park, with data: ParkData, city: City) throws {
        guard let category = ParkCategory(rawValue: data.category) else {
            throw ParkDataLoaderError.invalidCategory(data.category)
        }
        
        // Update park properties with new data
        park.name = data.name
        park.shortDescription = data.shortDescription
        park.fullDescription = data.fullDescription
        park.category = category
        park.latitude = data.latitude
        park.longitude = data.longitude
        park.address = data.address
        park.neighborhood = data.neighborhood
        park.acreage = data.acreage
        // Note: sfParksPropertyID should never change, so we don't update it
        park.city = city
    }
    
    private static func createPark(from data: ParkData, for city: City) throws -> Park {
        guard let category = ParkCategory(rawValue: data.category) else {
            throw ParkDataLoaderError.invalidCategory(data.category)
        }
        
        return Park(
            name: data.name,
            shortDescription: data.shortDescription,
            fullDescription: data.fullDescription,
            category: category,
            latitude: data.latitude,
            longitude: data.longitude,
            address: data.address,
            neighborhood: data.neighborhood,
            acreage: data.acreage,
            sfParksPropertyID: data.sfParksPropertyID,
            city: city
        )
    }
}

// MARK: - Error Handling

enum ParkDataLoaderError: LocalizedError {
    case fileNotFound
    case invalidCategory(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Could not find SFParks.json file in bundle"
        case .invalidCategory(let category):
            return "Invalid park category: \(category)"
        }
    }
}
