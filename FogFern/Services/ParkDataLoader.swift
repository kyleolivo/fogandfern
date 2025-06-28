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
    }
    
    struct ParksContainer: Codable {
        let version: String
        let parks: [ParkData]
        let generatedDate: String
    }
    
    // MARK: - Loading Functions
    
    static func loadParks(into modelContext: ModelContext, for city: City) throws {
        // Check if we already have the correct number of parks
        let parkDescriptor = FetchDescriptor<Park>()
        let existingParks = try modelContext.fetch(parkDescriptor)
        
        guard let url = Bundle.main.url(forResource: "SFParks", withExtension: "json") else {
            throw ParkDataLoaderError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let container = try JSONDecoder().decode(ParksContainer.self, from: data)
        
        // If we have the expected number of parks, don't reload
        if existingParks.count == container.parks.count {
            print("Parks already loaded correctly (\(existingParks.count) parks), skipping...")
            return
        }
        
        // Only clear if we have duplicates or wrong count
        if existingParks.count > container.parks.count {
            print("Found \(existingParks.count) parks, expected \(container.parks.count). Clearing duplicates...")
            clearExistingParks(from: modelContext)
        } else {
            print("Loading \(container.parks.count - existingParks.count) additional parks...")
        }
        
        // Get or create city
        let cityDescriptor = FetchDescriptor<City>()
        let existingCities = try modelContext.fetch(cityDescriptor)
        let freshCity = existingCities.first ?? {
            let newCity = City.sanFrancisco
            modelContext.insert(newCity)
            return newCity
        }()
        
        print("Loading \(container.parks.count) parks from JSON...")
        var insertedParkNames = Set<String>()
        
        // Add existing park names to avoid duplicates
        for existingPark in existingParks {
            insertedParkNames.insert(existingPark.name)
        }
        
        for parkData in container.parks {
            // Skip if we've already inserted a park with this name
            if insertedParkNames.contains(parkData.name) {
                continue
            }
            
            let park = try createPark(from: parkData, for: freshCity)
            modelContext.insert(park)
            insertedParkNames.insert(parkData.name)
        }
        
        print("Total unique parks in database: \(insertedParkNames.count)")
        
        // Save the new version
        UserDefaults.standard.set(container.version, forKey: "ParksDataVersion")
        
        try modelContext.save()
        print("Parks loaded successfully!")
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
            
            print("Deleting \(existingParks.count) existing parks...")
            for park in existingParks {
                modelContext.delete(park)
            }
            
            // Save after deleting parks to clear relationships
            try modelContext.save()
            print("Parks deleted, relationships cleared")
            
            // Now safely delete cities
            let cityDescriptor = FetchDescriptor<City>()
            let existingCities = try modelContext.fetch(cityDescriptor)
            
            print("Deleting \(existingCities.count) existing cities...")
            for city in existingCities {
                modelContext.delete(city)
            }
            
            try modelContext.save()
            print("Successfully cleared all existing data")
        } catch {
            print("Error clearing existing data: \(error)")
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
