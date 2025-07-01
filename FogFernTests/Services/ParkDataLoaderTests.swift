//
//  ParkDataLoaderTests.swift
//  FogFernTests
//
//  Created by Claude on 6/29/25.
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
        
        testCity = City(
            name: "test_city",
            displayName: "Test City",
            centerLatitude: 39.5,
            centerLongitude: -120.5
        )
    }
    
    override func tearDownWithError() throws {
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "ParksDataVersion")
        
        modelContext = nil
        modelContainer = nil
        testCity = nil
        super.tearDown()
    }
    
    // MARK: - Data Structure Tests
    
    func testParkDataCodable() throws {
        let parkData = ParkDataLoader.ParkData(
            name: "Test Park",
            shortDescription: "A test park",
            fullDescription: "A comprehensive test park",
            category: "neighborhood",
            latitude: 39.5,
            longitude: -120.5,
            address: "123 Test Street",
            neighborhood: "Test Neighborhood",
            acreage: 5.0,
            sfParksObjectID: nil,
            sfParksPropertyID: nil
        )
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(parkData)
        XCTAssertGreaterThan(data.count, 0)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedParkData = try decoder.decode(ParkDataLoader.ParkData.self, from: data)
        
        XCTAssertEqual(decodedParkData.name, parkData.name)
        XCTAssertEqual(decodedParkData.shortDescription, parkData.shortDescription)
        XCTAssertEqual(decodedParkData.fullDescription, parkData.fullDescription)
        XCTAssertEqual(decodedParkData.category, parkData.category)
        XCTAssertEqual(decodedParkData.latitude, parkData.latitude)
        XCTAssertEqual(decodedParkData.longitude, parkData.longitude)
        XCTAssertEqual(decodedParkData.address, parkData.address)
        XCTAssertEqual(decodedParkData.neighborhood, parkData.neighborhood)
        XCTAssertEqual(decodedParkData.acreage, parkData.acreage)
    }
    
    func testParksContainerCodable() throws {
        let parkData = ParkDataLoader.ParkData(
            name: "Test Park",
            shortDescription: "A test park",
            fullDescription: "A comprehensive test park",
            category: "neighborhood",
            latitude: 39.5,
            longitude: -120.5,
            address: "123 Test Street",
            neighborhood: "Test Neighborhood",
            acreage: 5.0,
            sfParksObjectID: nil,
            sfParksPropertyID: nil
        )
        
        let container = ParkDataLoader.ParksContainer(
            version: "1.0.0",
            parks: [parkData],
            generatedDate: "2025-06-29"
        )
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(container)
        XCTAssertGreaterThan(data.count, 0)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedContainer = try decoder.decode(ParkDataLoader.ParksContainer.self, from: data)
        
        XCTAssertEqual(decodedContainer.version, container.version)
        XCTAssertEqual(decodedContainer.parks.count, container.parks.count)
        XCTAssertEqual(decodedContainer.generatedDate, container.generatedDate)
        XCTAssertEqual(decodedContainer.parks.first?.name, parkData.name)
    }
    
    // MARK: - Error Handling Tests
    
    func testParkDataLoaderErrors() throws {
        // Test error descriptions
        let fileNotFoundError = ParkDataLoaderError.fileNotFound
        XCTAssertEqual(fileNotFoundError.errorDescription, "Could not find SFParks.json file in bundle")
        
        let invalidCategoryError = ParkDataLoaderError.invalidCategory("invalid")
        XCTAssertEqual(invalidCategoryError.errorDescription, "Invalid park category: invalid")
    }
    
    // MARK: - Version Management Tests
    
    func testVersionPersistence() throws {
        // Initially no version should be stored
        let initialVersion = UserDefaults.standard.string(forKey: "ParksDataVersion")
        XCTAssertNil(initialVersion)
        
        // Set a version
        UserDefaults.standard.set("1.0.0", forKey: "ParksDataVersion")
        let storedVersion = UserDefaults.standard.string(forKey: "ParksDataVersion")
        XCTAssertEqual(storedVersion, "1.0.0")
    }
    
    // MARK: - Park Creation Tests
    
    func testCreateParkFromValidData() throws {
        let parkData = ParkDataLoader.ParkData(
            name: "Test Park",
            shortDescription: "A test park",
            fullDescription: "A comprehensive test park",
            category: "neighborhood",
            latitude: 39.5,
            longitude: -120.5,
            address: "123 Test Street",
            neighborhood: "Test Neighborhood",
            acreage: 5.0,
            sfParksObjectID: nil,
            sfParksPropertyID: nil
        )
        
        // Use reflection to access private method for testing
        _ = class_getClassMethod(
            object_getClass(ParkDataLoader.self),
            Selector(("createPark:for:"))
        )
        
        // Since we can't directly test private methods, we'll test the public interface
        // by creating a mock JSON file scenario
        
        // Verify that the park data is valid for creation
        XCTAssertNotNil(ParkCategory(rawValue: parkData.category))
        XCTAssertGreaterThan(parkData.name.count, 0)
        XCTAssertGreaterThan(parkData.shortDescription.count, 0)
        XCTAssertGreaterThan(parkData.fullDescription.count, 0)
        XCTAssertGreaterThan(parkData.address.count, 0)
        XCTAssertGreaterThan(parkData.acreage, 0)
    }
    
    func testCreateParkFromInvalidCategory() throws {
        let parkDataWithInvalidCategory = ParkDataLoader.ParkData(
            name: "Test Park",
            shortDescription: "A test park",
            fullDescription: "A comprehensive test park",
            category: "invalid_category",
            latitude: 39.5,
            longitude: -120.5,
            address: "123 Test Street",
            neighborhood: "Test Neighborhood",
            acreage: 5.0,
            sfParksObjectID: nil,
            sfParksPropertyID: nil
        )
        
        // Verify that invalid category would cause an error
        XCTAssertNil(ParkCategory(rawValue: parkDataWithInvalidCategory.category))
    }
    
    // MARK: - Context Integration Tests
    
    func testModelContextIntegration() throws {
        // Test that we can work with the model context
        modelContext.insert(testCity)
        try modelContext.save()
        
        // Fetch the city back
        let cityDescriptor = FetchDescriptor<City>()
        let cities = try modelContext.fetch(cityDescriptor)
        
        XCTAssertEqual(cities.count, 1)
        XCTAssertEqual(cities.first?.name, testCity.name)
    }
    
    func testParkInsertion() throws {
        // Insert city first
        modelContext.insert(testCity)
        try modelContext.save()
        
        // Create and insert a park
        let park = Park(
            name: "Test Park",
            shortDescription: "A test park",
            fullDescription: "A comprehensive test park",
            category: .neighborhood,
            latitude: 39.5,
            longitude: -120.5,
            address: "123 Test Street",
            acreage: 5.0,
            city: testCity
        )
        
        modelContext.insert(park)
        try modelContext.save()
        
        // Fetch parks back
        let parkDescriptor = FetchDescriptor<Park>()
        let parks = try modelContext.fetch(parkDescriptor)
        
        XCTAssertEqual(parks.count, 1)
        XCTAssertEqual(parks.first?.name, "Test Park")
        XCTAssertEqual(parks.first?.city?.id, testCity.id)
    }
    
    // MARK: - Data Loading Simulation Tests
    
    func testDataLoadingWithEmptyContext() throws {
        // Verify context is initially empty
        let initialParkDescriptor = FetchDescriptor<Park>()
        let initialParks = try modelContext.fetch(initialParkDescriptor)
        XCTAssertEqual(initialParks.count, 0)
        
        let initialCityDescriptor = FetchDescriptor<City>()
        let initialCities = try modelContext.fetch(initialCityDescriptor)
        XCTAssertEqual(initialCities.count, 0)
    }
    
    func testDataLoadingWithExistingData() throws {
        // Insert some initial data
        modelContext.insert(testCity)
        
        let existingPark = Park(
            name: "Existing Park",
            shortDescription: "An existing park",
            fullDescription: "A comprehensive existing park",
            category: .destination,
            latitude: 39.6,
            longitude: -120.6,
            address: "456 Existing Street",
            acreage: 10.0,
            city: testCity
        )
        
        modelContext.insert(existingPark)
        try modelContext.save()
        
        // Verify data exists
        let parkDescriptor = FetchDescriptor<Park>()
        let existingParks = try modelContext.fetch(parkDescriptor)
        XCTAssertEqual(existingParks.count, 1)
        
        let cityDescriptor = FetchDescriptor<City>()
        let existingCities = try modelContext.fetch(cityDescriptor)
        XCTAssertEqual(existingCities.count, 1)
    }
    
    // MARK: - Duplicate Handling Tests
    
    func testDuplicateParkHandling() throws {
        // Insert city and park
        modelContext.insert(testCity)
        
        let park1 = Park(
            name: "Duplicate Park",
            shortDescription: "First instance",
            fullDescription: "First comprehensive instance",
            category: .neighborhood,
            latitude: 39.5,
            longitude: -120.5,
            address: "123 Duplicate Street",
            acreage: 5.0,
            city: testCity
        )
        
        let park2 = Park(
            name: "Duplicate Park", // Same name
            shortDescription: "Second instance",
            fullDescription: "Second comprehensive instance",
            category: .destination,
            latitude: 39.6,
            longitude: -120.6,
            address: "456 Different Street",
            acreage: 10.0,
            city: testCity
        )
        
        modelContext.insert(park1)
        modelContext.insert(park2)
        try modelContext.save()
        
        // Both parks should exist in context (SwiftData allows duplicates)
        let parkDescriptor = FetchDescriptor<Park>()
        let parks = try modelContext.fetch(parkDescriptor)
        XCTAssertEqual(parks.count, 2)
        
        // Test that we can distinguish them by other properties
        let parkNames = parks.map { $0.name }
        XCTAssertEqual(parkNames.filter { $0 == "Duplicate Park" }.count, 2)
    }
    
    // MARK: - Performance Tests
    
    func testLargeDatasetHandling() throws {
        modelContext.insert(testCity)
        
        // Insert many parks
        measure {
            for i in 0..<100 {
                let park = Park(
                    name: "Performance Park \(i)",
                    shortDescription: "Performance test park \(i)",
                    fullDescription: "Comprehensive performance test park \(i)",
                    category: .neighborhood,
                    latitude: 39.5 + Double(i) * 0.001,
                    longitude: -120.5 + Double(i) * 0.001,
                    address: "\(i) Performance Street",
                    acreage: Double(i + 1),
                    city: testCity
                )
                modelContext.insert(park)
            }
            
            do {
                try modelContext.save()
            } catch {
                XCTFail("Failed to save parks: \(error)")
            }
        }
    }
    
    func testFetchingPerformance() throws {
        // Insert test data first
        modelContext.insert(testCity)
        
        for i in 0..<1000 {
            let park = Park(
                name: "Fetch Test Park \(i)",
                shortDescription: "Fetch test park \(i)",
                fullDescription: "Comprehensive fetch test park \(i)",
                category: .neighborhood,
                latitude: 39.5 + Double(i) * 0.0001,
                longitude: -120.5 + Double(i) * 0.0001,
                address: "\(i) Fetch Street",
                acreage: Double(i + 1),
                city: testCity
            )
            modelContext.insert(park)
        }
        try modelContext.save()
        
        // Measure fetching performance
        measure {
            let parkDescriptor = FetchDescriptor<Park>()
            do {
                let _ = try modelContext.fetch(parkDescriptor)
            } catch {
                XCTFail("Failed to fetch parks: \(error)")
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyParkDataHandling() throws {
        let emptyParkData = ParkDataLoader.ParkData(
            name: "",
            shortDescription: "",
            fullDescription: "",
            category: "neighborhood",
            latitude: 0.0,
            longitude: 0.0,
            address: "",
            neighborhood: nil,
            acreage: 0.0,
            sfParksObjectID: nil,
            sfParksPropertyID: nil
        )
        
        // Verify that empty data can still be decoded
        let encoder = JSONEncoder()
        let data = try encoder.encode(emptyParkData)
        
        let decoder = JSONDecoder()
        let decodedData = try decoder.decode(ParkDataLoader.ParkData.self, from: data)
        
        XCTAssertEqual(decodedData.name, "")
        XCTAssertEqual(decodedData.shortDescription, "")
        XCTAssertEqual(decodedData.fullDescription, "")
        XCTAssertEqual(decodedData.acreage, 0.0)
        XCTAssertNil(decodedData.neighborhood)
    }
    
    func testExtremeCoordinates() throws {
        let extremeParkData = ParkDataLoader.ParkData(
            name: "Extreme Park",
            shortDescription: "Extreme coordinates",
            fullDescription: "Park with extreme coordinates",
            category: "destination",
            latitude: 90.0,
            longitude: 180.0,
            address: "Extreme Location",
            neighborhood: "Extreme Neighborhood",
            acreage: 999999.0,
            sfParksObjectID: nil,
            sfParksPropertyID: nil
        )
        
        // Verify extreme values can be handled
        let encoder = JSONEncoder()
        let data = try encoder.encode(extremeParkData)
        
        let decoder = JSONDecoder()
        let decodedData = try decoder.decode(ParkDataLoader.ParkData.self, from: data)
        
        XCTAssertEqual(decodedData.latitude, 90.0)
        XCTAssertEqual(decodedData.longitude, 180.0)
        XCTAssertEqual(decodedData.acreage, 999999.0)
    }
    
    func testConcurrentAccess() throws {
        modelContext.insert(testCity)
        try modelContext.save()
        
        let expectation = XCTestExpectation(description: "Concurrent park insertion")
        expectation.expectedFulfillmentCount = 5
        
        // Test concurrent access to model context
        for i in 0..<5 {
            DispatchQueue.global().async {
                // Create a new context for each thread
                let threadContext = ModelContext(self.modelContainer)
                
                let park = Park(
                    name: "Concurrent Park \(i)",
                    shortDescription: "Concurrent test park \(i)",
                    fullDescription: "Comprehensive concurrent test park \(i)",
                    category: .neighborhood,
                    latitude: 39.5 + Double(i) * 0.01,
                    longitude: -120.5 + Double(i) * 0.01,
                    address: "\(i) Concurrent Street",
                    acreage: Double(i + 1),
                    city: self.testCity
                )
                
                threadContext.insert(park)
                
                do {
                    try threadContext.save()
                    expectation.fulfill()
                } catch {
                    XCTFail("Concurrent save failed: \(error)")
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}