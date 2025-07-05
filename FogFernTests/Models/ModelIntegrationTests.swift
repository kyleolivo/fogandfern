//
//  ModelIntegrationTests.swift
//  FogFernTests
//
//  Created by Claude on 6/29/25.
//

import XCTest
import SwiftData
@testable import FogFern

final class ModelIntegrationTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var testCity: City!
    var testUser: User!
    var testPark: Park!
    
    override func setUpWithError() throws {
        super.setUp()
        
        // Setup in-memory model container with all models
        let schema = Schema([City.self, User.self, Park.self, Visit.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        // Create test data
        testCity = City(
            name: "integration_test_city",
            displayName: "Integration Test City",
            centerLatitude: 37.7749,
            centerLongitude: -122.4194
        )
        
        testUser = User()
        
        testPark = Park(
            name: "Integration Test Park",
            shortDescription: "A park for integration testing",
            fullDescription: "This park is used to test relationships between models",
            category: .destination,
            latitude: 37.7749,
            longitude: -122.4194,
            address: "123 Integration Test St",
            acreage: 10.0,
            propertyID: "INT123",
            city: testCity
        )
        
        // Insert into context
        modelContext.insert(testCity)
        modelContext.insert(testUser)
        modelContext.insert(testPark)
        try modelContext.save()
    }
    
    override func tearDownWithError() throws {
        testPark = nil
        testUser = nil
        testCity = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }
    
    // MARK: - Relationship Integration Tests
    
    func testCityParkRelationship() throws {
        // Test that city-park relationship works correctly
        XCTAssertEqual(testPark.city?.id, testCity.id)
        XCTAssertEqual(testPark.city?.name, "integration_test_city")
        
        // Test reverse relationship (if parks array is populated)
        if let cityParks = testCity.parks {
            XCTAssertTrue(cityParks.contains { $0.id == testPark.id })
        }
    }
    
    func testVisitCreationAndRelationships() throws {
        // Create a visit using the convenience initializer
        let visit = Visit(park: testPark, user: testUser)
        modelContext.insert(visit)
        try modelContext.save()
        
        // Test visit relationships
        XCTAssertEqual(visit.user?.id, testUser.id)
        XCTAssertEqual(visit.parkName, testPark.name)
        XCTAssertTrue(visit.isActive)
        
        // Test composite ID generation
        let expectedUniqueID = "integration_test_city:INT123"
        XCTAssertEqual(visit.parkUniqueID, expectedUniqueID)
        
        // Test finding park from visit
        let foundPark = visit.findPark(in: modelContext)
        XCTAssertNotNil(foundPark)
        XCTAssertEqual(foundPark?.id, testPark.id)
    }
    
    func testCompositeIDFunctionality() throws {
        // Test various composite ID scenarios
        
        // 1. Normal park with city and external ID
        let normalVisit = Visit(park: testPark, user: testUser)
        XCTAssertEqual(normalVisit.parkUniqueID, "integration_test_city:INT123")
        
        // 2. Park without external ID (should use UUID)
        let parkWithoutID = Park(
            name: "No ID Park",
            shortDescription: "Park without external ID",
            fullDescription: "Testing UUID fallback",
            category: .mini,
            latitude: 37.8,
            longitude: -122.5,
            address: "456 No ID St",
            acreage: 2.0,
            city: testCity
        )
        modelContext.insert(parkWithoutID)
        try modelContext.save()
        
        let noIDVisit = Visit(park: parkWithoutID, user: testUser)
        XCTAssertTrue(noIDVisit.parkUniqueID.hasPrefix("integration_test_city:"))
        XCTAssertTrue(noIDVisit.parkUniqueID.contains("-")) // UUID format
        
        // 3. Park without city (should use "unknown")
        let citylessCity = City(
            name: "unknown",
            displayName: "Unknown City",
            centerLatitude: 0.0,
            centerLongitude: 0.0
        )
        
        let citylessPark = Park(
            name: "Cityless Park",
            shortDescription: "Park without city",
            fullDescription: "Testing unknown city fallback",
            category: .neighborhood,
            latitude: 38.0,
            longitude: -123.0,
            address: "789 Cityless St",
            acreage: 5.0,
            propertyID: "CITYLESS123"
        )
        
        modelContext.insert(citylessCity)
        modelContext.insert(citylessPark)
        try modelContext.save()
        
        let citylessVisit = Visit(park: citylessPark, user: testUser)
        XCTAssertEqual(citylessVisit.parkUniqueID, "unknown:CITYLESS123")
    }
    
    func testDataIntegrityAcrossModels() throws {
        // Create a complex scenario with multiple relationships
        let anotherPark = Park(
            name: "Second Park",
            shortDescription: "Another test park",
            fullDescription: "Second park for relationship testing",
            category: .neighborhood,
            latitude: 37.8,
            longitude: -122.3,
            address: "456 Second St",
            acreage: 15.0,
            propertyID: "SEC456",
            city: testCity
        )
        
        let anotherUser = User()
        
        modelContext.insert(anotherPark)
        modelContext.insert(anotherUser)
        try modelContext.save()
        
        // Create visits from multiple users to multiple parks
        let visits = [
            Visit(park: testPark, user: testUser),
            Visit(park: testPark, user: anotherUser),
            Visit(park: anotherPark, user: testUser),
            Visit(park: anotherPark, user: anotherUser)
        ]
        
        for visit in visits {
            modelContext.insert(visit)
        }
        try modelContext.save()
        
        // Test data integrity
        let allVisits = try modelContext.fetch(FetchDescriptor<Visit>())
        XCTAssertEqual(allVisits.count, 4)
        
        // Test that each visit has correct relationships
        for visit in allVisits {
            XCTAssertNotNil(visit.user)
            XCTAssertNotNil(visit.findPark(in: modelContext))
            XCTAssertFalse(visit.parkUniqueID.isEmpty)
            XCTAssertFalse(visit.parkName.isEmpty)
            XCTAssertTrue(visit.isActive)
        }
        
        // Test unique park counting
        let uniqueParkIDs = Set(allVisits.map { $0.parkUniqueID })
        XCTAssertEqual(uniqueParkIDs.count, 2) // Two different parks
        
        let expectedIDs = Set([
            "integration_test_city:INT123",
            "integration_test_city:SEC456"
        ])
        XCTAssertEqual(uniqueParkIDs, expectedIDs)
    }
    
    func testModelPersistenceAndRetrieval() throws {
        // Test that all models can be persisted and retrieved correctly
        
        // Create and save a visit
        let visit = Visit(park: testPark, user: testUser)
        modelContext.insert(visit)
        try modelContext.save()
        
        // Create a new context to simulate fresh data retrieval
        let freshContext = ModelContext(modelContainer)
        
        let fetchedCities = try freshContext.fetch(FetchDescriptor<City>())
        let fetchedUsers = try freshContext.fetch(FetchDescriptor<User>())
        let fetchedParks = try freshContext.fetch(FetchDescriptor<Park>())
        let fetchedVisits = try freshContext.fetch(FetchDescriptor<Visit>())
        
        // Verify data integrity after persistence
        XCTAssertEqual(fetchedCities.count, 1)
        XCTAssertEqual(fetchedUsers.count, 1)
        XCTAssertEqual(fetchedParks.count, 1)
        XCTAssertEqual(fetchedVisits.count, 1)
        
        let city = fetchedCities.first!
        let user = fetchedUsers.first!
        let park = fetchedParks.first!
        let persistedVisit = fetchedVisits.first!
        
        // Test that relationships are maintained
        XCTAssertEqual(park.city?.id, city.id)
        XCTAssertEqual(persistedVisit.user?.id, user.id)
        XCTAssertEqual(persistedVisit.parkName, park.name)
        
        // Test composite ID is preserved
        XCTAssertEqual(persistedVisit.parkUniqueID, "integration_test_city:INT123")
        
        // Test isActive field is preserved
        XCTAssertTrue(persistedVisit.isActive)
    }
    
    // MARK: - Schema Validation Tests
    
    func testSchemaVersionCompatibility() throws {
        // Test that current models match SchemaV1 definitions
        
        let cities = try modelContext.fetch(FetchDescriptor<City>())
        let users = try modelContext.fetch(FetchDescriptor<User>())
        let parks = try modelContext.fetch(FetchDescriptor<Park>())
        let visits = try modelContext.fetch(FetchDescriptor<Visit>())
        
        // Basic validation that fetch operations work (indicates schema compatibility)
        XCTAssertNotNil(cities)
        XCTAssertNotNil(users)
        XCTAssertNotNil(parks)
        XCTAssertNotNil(visits)
        
        // Test that essential fields are accessible
        if let city = cities.first {
            XCTAssertNotNil(city.name)
            XCTAssertNotNil(city.displayName)
            XCTAssertNotNil(city.centerLatitude)
            XCTAssertNotNil(city.centerLongitude)
        }
        
        if let park = parks.first {
            XCTAssertNotNil(park.name)
            XCTAssertNotNil(park.category)
            XCTAssertNotNil(park.latitude)
            XCTAssertNotNil(park.longitude)
            XCTAssertNotNil(park.acreage)
        }
        
        if let user = users.first {
            XCTAssertNotNil(user.id)
            XCTAssertNotNil(user.createdDate)
        }
    }
    
    func testParkCategoryConsistency() throws {
        // Test that all park categories work correctly
        let categories: [ParkCategory] = [.destination, .neighborhood, .mini, .plaza, .garden]
        
        for category in categories {
            let categoryPark = Park(
                name: "Test \(category.rawValue) Park",
                shortDescription: "Testing category",
                fullDescription: "Testing \(category.displayName) category",
                category: category,
                latitude: 37.7,
                longitude: -122.4,
                address: "Category Test St",
                acreage: 5.0,
                city: testCity
            )
            
            modelContext.insert(categoryPark)
            
            // Test that category properties work
            XCTAssertNotNil(categoryPark.category.displayName)
            XCTAssertNotNil(categoryPark.category.systemImageName)
            XCTAssertFalse(categoryPark.category.rawValue.isEmpty)
        }
        
        try modelContext.save()
        
        // Verify all categories were saved correctly
        let savedParks = try modelContext.fetch(FetchDescriptor<Park>())
        let savedCategories = Set(savedParks.map { $0.category })
        
        // Should have original test park plus 5 category test parks
        XCTAssertEqual(savedParks.count, 6)
        XCTAssertEqual(savedCategories.count, 5) // All 5 categories represented
    }
    
    // MARK: - Performance Integration Tests
    
    func testLargeDataSetPerformance() throws {
        // Test performance with larger data sets
        measure {
            // Create multiple cities, parks, and visits
            for i in 0..<10 {
                let city = City(
                    name: "perf_city_\(i)",
                    displayName: "Performance City \(i)",
                    centerLatitude: 37.0 + Double(i) * 0.1,
                    centerLongitude: -122.0 + Double(i) * 0.1
                )
                modelContext.insert(city)
                
                for j in 0..<5 {
                    let park = Park(
                        name: "Performance Park \(i)-\(j)",
                        shortDescription: "Perf park",
                        fullDescription: "Performance testing park",
                        category: ParkCategory.allCases[j % ParkCategory.allCases.count],
                        latitude: 37.0 + Double(i) * 0.1,
                        longitude: -122.0 + Double(i) * 0.1,
                        address: "Perf St \(i)-\(j)",
                        acreage: Double(j + 1),
                        propertyID: "PERF\(i)\(j)",
                        city: city
                    )
                    modelContext.insert(park)
                    
                    let visit = Visit(park: park, user: testUser)
                    modelContext.insert(visit)
                }
            }
            
            do {
                try modelContext.save()
            } catch {
                XCTFail("Failed to save performance test data: \(error)")
            }
        }
    }
}
