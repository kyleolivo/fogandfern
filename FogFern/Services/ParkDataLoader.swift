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
        let existingSFParksIDs = Set(existingParks.compactMap { $0.sfParksPropertyID })
        
        // If we have the expected number of parks and it's not zero, don't reload
        if existingParks.count == container.parks.count && existingParks.count > 0 {
            return
        }
        
        // Only clear if we have duplicates or wrong count
        if existingParks.count > container.parks.count {
            clearExistingParks(from: modelContext)
        }
        
        // Get or create city in this context
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
        
        for parkData in container.parks {
            // Skip if we already have a park with this SF Parks ID
            if let propertyID = parkData.sfParksPropertyID, existingSFParksIDs.contains(propertyID) {
                continue
            }
            
            let park = try createPark(from: parkData, for: contextCity)
            modelContext.insert(park)
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
