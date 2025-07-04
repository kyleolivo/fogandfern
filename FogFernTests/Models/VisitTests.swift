//
//  VisitTests.swift
//  FogFernTests
//
//  Created by Claude on 6/29/25.
//

import XCTest
import SwiftData
@testable import FogFern

final class VisitTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var testUser: User!
    var testCity: City!
    var testPark: Park!
    var testVisit: Visit!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        super.setUp()
        
        // Setup in-memory model container
        let schema = Schema([Visit.self, User.self, Park.self, City.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        testUser = User()
        
        testCity = City(
            name: "test_city",
            displayName: "Test City",
            centerLatitude: 39.5,
            centerLongitude: -120.5
        )
        
        testPark = Park(
            name: "Test Park",
            shortDescription: "A test park",
            fullDescription: "A comprehensive test park",
            category: .neighborhood,
            latitude: 39.5,
            longitude: -120.5,
            address: "123 Test Street",
            acreage: 5.0,
            sfParksPropertyID: "TEST123",
            city: testCity
        )
        
        testVisit = Visit(
            timestamp: Date(),
            parkUniqueID: Visit.generateUniqueID(for: testPark),
            parkName: testPark.name,
            user: testUser
        )
        
        // Insert all objects into context
        modelContext.insert(testUser)
        modelContext.insert(testCity)
        modelContext.insert(testPark)
        modelContext.insert(testVisit)
    }
    
    override func tearDownWithError() throws {
        testVisit = nil
        testPark = nil
        testCity = nil
        testUser = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testVisitInitialization() throws {
        XCTAssertNotNil(testVisit.id)
        XCTAssertNotNil(testVisit.timestamp)
        XCTAssertEqual(testVisit.parkUniqueID, "test_city:TEST123")
        XCTAssertEqual(testVisit.parkName, "Test Park")
        XCTAssertEqual(testVisit.user?.id, testUser.id)
    }
    
    func testVisitInitializationWithDefaults() throws {
        let defaultVisit = Visit()
        XCTAssertNotNil(defaultVisit.id)
        XCTAssertNotNil(defaultVisit.timestamp)
        XCTAssertEqual(defaultVisit.parkUniqueID, "")
        XCTAssertEqual(defaultVisit.parkName, "")
        XCTAssertNil(defaultVisit.user)
    }
    
    func testVisitConvenienceInitializerWithPark() throws {
        let visitWithPark = Visit(
            park: testPark,
            user: testUser
        )
        
        XCTAssertEqual(visitWithPark.parkUniqueID, "test_city:TEST123")
        XCTAssertEqual(visitWithPark.parkName, "Test Park")
        XCTAssertEqual(visitWithPark.user?.id, testUser.id)
    }
    
    // MARK: - Park Finding Tests
    
    func testFindParkInContext() throws {
        let foundPark = testVisit.findPark(in: modelContext)
        XCTAssertNotNil(foundPark)
        XCTAssertEqual(foundPark?.id, testPark.id)
        XCTAssertEqual(foundPark?.sfParksPropertyID, "TEST123")
    }
    
    func testFindParkWithInvalidID() throws {
        let invalidVisit = Visit(
            parkUniqueID: "test_city:INVALID",
            parkName: "Unknown Park",
            user: testUser
        )
        modelContext.insert(invalidVisit)
        
        let foundPark = invalidVisit.findPark(in: modelContext)
        XCTAssertNil(foundPark)
    }
    
    func testFindParkWithEmptyID() throws {
        let emptyVisit = Visit(
            parkUniqueID: "",
            parkName: "No ID Park",
            user: testUser
        )
        modelContext.insert(emptyVisit)
        
        let foundPark = emptyVisit.findPark(in: modelContext)
        XCTAssertNil(foundPark)
    }
    
    
    // MARK: - Timestamp Tests
    
    func testTimestampIsRecent() throws {
        let now = Date()
        let timeDifference = now.timeIntervalSince(testVisit.timestamp)
        XCTAssertLessThan(timeDifference, 1.0)
    }
    
    func testCustomTimestamp() throws {
        let pastDate = Date(timeIntervalSinceNow: -3600) // 1 hour ago
        let pastVisit = Visit(
            timestamp: pastDate,
            park: testPark,
            user: testUser
        )
        XCTAssertEqual(pastVisit.timestamp, pastDate)
    }
    
    // MARK: - Relationship Tests
    
    func testUserRelationship() throws {
        XCTAssertEqual(testVisit.user?.id, testUser.id)
    }
    
    func testVisitWithoutUser() throws {
        let orphanVisit = Visit(
            parkUniqueID: "test_city:TEST456",
            parkName: "Another Park"
        )
        XCTAssertNil(orphanVisit.user)
    }
    
    // MARK: - Edge Cases Tests
    
    func testVisitWithNilParkSFParksPropertyID() throws {
        let parkWithoutID = Park(
            name: "No ID Park",
            shortDescription: "Park without SF ID",
            fullDescription: "This park has no SF Parks ID",
            category: .mini,
            latitude: 40.0,
            longitude: -120.0,
            address: "456 Test Ave",
            acreage: 1.0,
            city: testCity
        )
        modelContext.insert(parkWithoutID)
        
        let visitToNilIDPark = Visit(
            park: parkWithoutID,
            user: testUser
        )
        
        // When park has no external ID, it uses the park's UUID instead
        XCTAssertTrue(visitToNilIDPark.parkUniqueID.hasPrefix("test_city:"))
        XCTAssertTrue(visitToNilIDPark.parkUniqueID.count > "test_city:".count)
        XCTAssertEqual(visitToNilIDPark.parkName, "No ID Park")
    }
    
    // MARK: - Performance Tests
    
    func testVisitInitializationPerformance() throws {
        measure {
            for _ in 0..<1000 {
                let _ = Visit(
                    park: testPark,
                    user: testUser
                )
            }
        }
    }
    
    func testFindParkPerformance() throws {
        // Add more parks to make the search more realistic
        for i in 0..<100 {
            let park = Park(
                name: "Park \(i)",
                shortDescription: "Park \(i)",
                fullDescription: "Park \(i) description",
                category: .neighborhood,
                latitude: 39.5 + Double(i) * 0.001,
                longitude: -120.5 + Double(i) * 0.001,
                address: "\(i) Park Street",
                acreage: Double(i),
                sfParksPropertyID: "PARK\(i)",
                city: testCity
            )
            modelContext.insert(park)
        }
        
        try modelContext.save()
        
        measure {
            for _ in 0..<100 {
                let _ = testVisit.findPark(in: modelContext)
            }
        }
    }
}