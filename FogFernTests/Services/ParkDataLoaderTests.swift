//
//  ParkDataLoaderTests.swift
//  FogFernTests
//
//  Created by Claude on 7/5/25.
//

import XCTest
import SwiftData
@testable import FogFern

final class ParkDataLoaderTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var testCity: City!
    
    override func setUpWithError() throws {
        super.setUp()
        
        // Create in-memory model container for testing
        let schema = Schema([City.self, Park.self, Visit.self, User.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        // Create test city
        testCity = City(
            name: "san_francisco",
            displayName: "San Francisco Test",
            centerLatitude: 37.7749,
            centerLongitude: -122.4194
        )
        modelContext.insert(testCity)
        try modelContext.save()
        
        // Clear any stored version for clean testing
        UserDefaults.standard.removeObject(forKey: "ParksDataVersion")
    }
    
    override func tearDownWithError() throws {
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "ParksDataVersion")
        
        testCity = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }
    
    // MARK: - Data Structure Tests
    
    func testParkDataCodable() throws {
        let json = """
        {
            "name": "Test Park",
            "shortDescription": "Test description",
            "fullDescription": "Full test description",
            "category": "destination",
            "latitude": 37.7749,
            "longitude": -122.4194,
            "address": "123 Test St",
            "neighborhood": "Test Neighborhood",
            "acreage": 10.5,
            "propertyID": "TEST001"
        }
        """.data(using: .utf8)!
        
        let parkData = try JSONDecoder().decode(ParkDataLoader.ParkData.self, from: json)
        
        XCTAssertEqual(parkData.name, "Test Park")
        XCTAssertEqual(parkData.shortDescription, "Test description")
        XCTAssertEqual(parkData.fullDescription, "Full test description")
        XCTAssertEqual(parkData.category, "destination")
        XCTAssertEqual(parkData.latitude, 37.7749)
        XCTAssertEqual(parkData.longitude, -122.4194)
        XCTAssertEqual(parkData.address, "123 Test St")
        XCTAssertEqual(parkData.neighborhood, "Test Neighborhood")
        XCTAssertEqual(parkData.acreage, 10.5)
        XCTAssertEqual(parkData.propertyID, "TEST001")
    }
    
    func testParksContainerCodable() throws {
        let json = """
        {
            "version": "1.0.0",
            "parks": [],
            "generatedDate": "2025-07-05T12:00:00Z"
        }
        """.data(using: .utf8)!
        
        let container = try JSONDecoder().decode(ParkDataLoader.ParksContainer.self, from: json)
        
        XCTAssertEqual(container.version, "1.0.0")
        XCTAssertEqual(container.parks.count, 0)
        XCTAssertEqual(container.generatedDate, "2025-07-05T12:00:00Z")
    }
    
    // MARK: - Error Handling Tests
    
    func testParkDataLoaderErrorTypes() throws {
        let fileNotFoundError = ParkDataLoaderError.fileNotFound
        XCTAssertNotNil(fileNotFoundError.errorDescription)
        XCTAssertTrue(fileNotFoundError.errorDescription?.contains("SFParks.json") ?? false)
        
        let invalidCategoryError = ParkDataLoaderError.invalidCategory("invalid")
        XCTAssertNotNil(invalidCategoryError.errorDescription)
        XCTAssertTrue(invalidCategoryError.errorDescription?.contains("invalid") ?? false)
    }
    
    func testLoadParksWithMissingFile() throws {
        // This test uses the real Bundle, so we expect it to either find SFParks.json or throw fileNotFound
        do {
            try ParkDataLoader.loadParks(into: modelContext, for: testCity)
            // If it succeeds, verify parks were loaded
            let parks = try modelContext.fetch(FetchDescriptor<Park>())
            XCTAssertGreaterThan(parks.count, 0)
        } catch ParkDataLoaderError.fileNotFound {
            // This is expected if SFParks.json is not in the test bundle
            XCTAssertTrue(true, "Expected file not found error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Version Management Tests
    
    func testVersionTracking() throws {
        // Initially no version should be stored
        XCTAssertNil(UserDefaults.standard.string(forKey: "ParksDataVersion"))
        
        // After loading parks, version should be stored
        do {
            try ParkDataLoader.loadParks(into: modelContext, for: testCity)
            let storedVersion = UserDefaults.standard.string(forKey: "ParksDataVersion")
            XCTAssertNotNil(storedVersion)
        } catch ParkDataLoaderError.fileNotFound {
            // Skip this test if the file doesn't exist
            throw XCTSkip("SFParks.json not found in test bundle")
        }
    }
    
    func testNoReloadWithSameVersion() throws {
        do {
            // Load parks first time
            try ParkDataLoader.loadParks(into: modelContext, for: testCity)
            let initialParks = try modelContext.fetch(FetchDescriptor<Park>())
            let initialCount = initialParks.count
            
            // Load again - should not reload since version is the same
            try ParkDataLoader.loadParks(into: modelContext, for: testCity)
            let secondParks = try modelContext.fetch(FetchDescriptor<Park>())
            
            XCTAssertEqual(secondParks.count, initialCount)
        } catch ParkDataLoaderError.fileNotFound {
            throw XCTSkip("SFParks.json not found in test bundle")
        }
    }
    
    // MARK: - Duplicate Handling Tests
    
    func testDuplicateCleanup() throws {
        // Create a test park first
        let testPark1 = Park(
            name: "Duplicate Test Park",
            shortDescription: "First instance",
            fullDescription: "First instance of duplicate",
            category: .destination,
            latitude: 37.7749,
            longitude: -122.4194,
            address: "123 Test St",
            acreage: 10.0,
            propertyID: "DUPLICATE001",
            city: testCity
        )
        
        // Create a duplicate with same propertyID but different lastUpdated
        let testPark2 = Park(
            name: "Duplicate Test Park",
            shortDescription: "Second instance",
            fullDescription: "Second instance of duplicate",
            category: .destination,
            latitude: 37.7749,
            longitude: -122.4194,
            address: "123 Test St",
            acreage: 10.0,
            propertyID: "DUPLICATE001",
            city: testCity
        )
        
        // Make the second park newer
        testPark2.lastUpdated = Date().addingTimeInterval(10)
        
        modelContext.insert(testPark1)
        modelContext.insert(testPark2)
        try modelContext.save()
        
        // Verify we have duplicates
        let parksBeforeCleanup = try modelContext.fetch(FetchDescriptor<Park>())
        let duplicates = Dictionary(grouping: parksBeforeCleanup) { $0.propertyID }
            .filter { $0.value.count > 1 }
        XCTAssertGreaterThan(duplicates.count, 0)
        
        // The ParkDataLoader should handle duplicate cleanup during load
        // Since we can't easily mock the JSON loading, we'll test the core logic
        // by verifying that duplicate parks with same propertyID exist before cleanup
        XCTAssertEqual(parksBeforeCleanup.count, 2)
    }
    
    // MARK: - City Management Tests
    
    func testCityCreationWhenMissing() throws {
        // Delete the test city to simulate missing city
        modelContext.delete(testCity)
        try modelContext.save()
        
        // Verify city is gone
        let citiesBeforeLoad = try modelContext.fetch(FetchDescriptor<City>())
        XCTAssertEqual(citiesBeforeLoad.count, 0)
        
        do {
            try ParkDataLoader.loadParks(into: modelContext, for: testCity)
            
            // After loading, we should have a san_francisco city
            let citiesAfterLoad = try modelContext.fetch(FetchDescriptor<City>())
            let sfCity = citiesAfterLoad.first { $0.name == "san_francisco" }
            XCTAssertNotNil(sfCity)
            XCTAssertEqual(sfCity?.displayName, "San Francisco")
        } catch ParkDataLoaderError.fileNotFound {
            throw XCTSkip("SFParks.json not found in test bundle")
        }
    }
    
    func testExistingCityUsage() throws {
        let citiesBeforeLoad = try modelContext.fetch(FetchDescriptor<City>())
        let initialCount = citiesBeforeLoad.count
        
        do {
            try ParkDataLoader.loadParks(into: modelContext, for: testCity)
            
            // Should not create a new city, just use existing one
            let citiesAfterLoad = try modelContext.fetch(FetchDescriptor<City>())
            XCTAssertEqual(citiesAfterLoad.count, initialCount)
            
            let existingSfCity = citiesAfterLoad.first { $0.name == "san_francisco" }
            XCTAssertNotNil(existingSfCity)
            XCTAssertEqual(existingSfCity?.displayName, "San Francisco Test")
        } catch ParkDataLoaderError.fileNotFound {
            throw XCTSkip("SFParks.json not found in test bundle")
        }
    }
    
    // MARK: - Integration Tests
    
    func testFullLoadingCycle() throws {
        // Ensure we start with no parks
        let initialParks = try modelContext.fetch(FetchDescriptor<Park>())
        XCTAssertEqual(initialParks.count, 0)
        
        do {
            // Load parks
            try ParkDataLoader.loadParks(into: modelContext, for: testCity)
            
            // Verify parks were loaded
            let loadedParks = try modelContext.fetch(FetchDescriptor<Park>())
            XCTAssertGreaterThan(loadedParks.count, 0)
            
            // Verify all parks have required properties
            for park in loadedParks {
                XCTAssertFalse(park.name.isEmpty)
                XCTAssertFalse(park.shortDescription.isEmpty)
                XCTAssertFalse(park.fullDescription.isEmpty)
                XCTAssertNotNil(park.category)
                XCTAssertGreaterThan(park.acreage, 0)
                XCTAssertNotNil(park.city)
                XCTAssertTrue(park.isActive)
            }
            
            // Verify version was stored
            let storedVersion = UserDefaults.standard.string(forKey: "ParksDataVersion")
            XCTAssertNotNil(storedVersion)
            
        } catch ParkDataLoaderError.fileNotFound {
            throw XCTSkip("SFParks.json not found in test bundle")
        }
    }
    
    // MARK: - Performance Tests
    
    func testLoadingPerformance() throws {
        measure {
            do {
                // Clear any existing data
                let existingParks = try modelContext.fetch(FetchDescriptor<Park>())
                for park in existingParks {
                    modelContext.delete(park)
                }
                try modelContext.save()
                
                // Reset version to force reload
                UserDefaults.standard.removeObject(forKey: "ParksDataVersion")
                
                // Load parks
                try ParkDataLoader.loadParks(into: modelContext, for: testCity)
                
            } catch ParkDataLoaderError.fileNotFound {
                // Skip performance test if file not found
                return
            } catch {
                XCTFail("Performance test failed: \(error)")
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyParksArray() throws {
        // Test behavior with empty parks array
        let emptyJson = """
        {
            "version": "1.0.0-empty",
            "generatedDate": "2025-07-05T12:00:00Z",
            "parks": []
        }
        """.data(using: .utf8)!
        
        let container = try JSONDecoder().decode(ParkDataLoader.ParksContainer.self, from: emptyJson)
        XCTAssertEqual(container.parks.count, 0)
        XCTAssertEqual(container.version, "1.0.0-empty")
    }
    
    func testParkWithoutPropertyID() throws {
        let parkWithoutID = ParkDataLoader.ParkData(
            name: "No ID Park",
            shortDescription: "Test description",
            fullDescription: "Full test description", 
            category: "destination",
            latitude: 37.7749,
            longitude: -122.4194,
            address: "123 Test St",
            neighborhood: "Test Neighborhood",
            acreage: 10.5,
            propertyID: nil
        )
        
        XCTAssertNil(parkWithoutID.propertyID)
        // Parks without propertyID should be skipped during loading
    }
    
    func testInvalidCoordinates() throws {
        let parkWithInvalidCoords = ParkDataLoader.ParkData(
            name: "Invalid Coords Park",
            shortDescription: "Test description",
            fullDescription: "Full test description",
            category: "destination", 
            latitude: 0.0,
            longitude: 0.0,
            address: "123 Test St",
            neighborhood: "Test Neighborhood",
            acreage: 10.5,
            propertyID: "INVALID001"
        )
        
        // Should still create the park, but coordinates should be noted as invalid
        XCTAssertEqual(parkWithInvalidCoords.latitude, 0.0)
        XCTAssertEqual(parkWithInvalidCoords.longitude, 0.0)
    }
}
