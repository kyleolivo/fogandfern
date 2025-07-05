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
        let propertyID: String?
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
        
        // Check existing parks
        let existingParks = try modelContext.fetch(FetchDescriptor<Park>())
        
        // Check if we need to update based on version
        let storedVersion = UserDefaults.standard.string(forKey: "ParksDataVersion")
        let needsUpdate = storedVersion != container.version
        
        // If we have parks and the version matches, no need to reload
        if existingParks.count > 0 && !needsUpdate {
            return
        }
        
        // Build a map of existing parks by property ID for efficient lookup
        let existingParksMap: [String: Park] = Dictionary(
            existingParks.compactMap { park in
                guard let propertyID = park.propertyID else { return nil }
                return (propertyID, park)
            },
            uniquingKeysWith: { first, _ in first }
        )
        
        // Check for duplicates (CloudKit sync issues)
        let existingByID = Dictionary(grouping: existingParks) { $0.propertyID }
        let hasDuplicates = existingByID.values.contains { $0.count > 1 }
        
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
        
        // Clean up duplicates if they exist
        if hasDuplicates {
            let duplicateGroups = existingByID.filter { $0.value.count > 1 }
            for (_, duplicates) in duplicateGroups {
                // Keep the most recent one, delete the rest
                let sorted = duplicates.sorted { $0.lastUpdated > $1.lastUpdated }
                for park in sorted.dropFirst() {
                    modelContext.delete(park)
                }
            }
            try modelContext.save()
        }
        
        // Process each park in the data
        for parkData in container.parks {
            guard let propertyID = parkData.propertyID else {
                print("Warning: Park '\(parkData.name)' has no propertyID")
                continue
            }
            
            if let existingPark = existingParksMap[propertyID] {
                // Update existing park with new data (preserving visits)
                try updatePark(existingPark, with: parkData, city: contextCity)
            } else {
                // This is a new park, create it
                let park = try createPark(from: parkData, for: contextCity)
                modelContext.insert(park)
            }
        }
        
        // Save the new version
        UserDefaults.standard.set(container.version, forKey: "ParksDataVersion")
        
        try modelContext.save()
    }
    
    // MARK: - Helper Functions
    
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
        // Note: propertyID should never change, so we don't update it
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
            propertyID: data.propertyID,
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
