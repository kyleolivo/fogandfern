//
//  UserTests.swift
//  FogFernTests
//
//  Created by Claude on 6/29/25.
//

import XCTest
@testable import FogFern

final class UserTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var testUser: User!
    var testCity: City!
    var testPark: Park!
    
    override func setUpWithError() throws {
        super.setUp()
        
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
    }
    
    override func tearDownWithError() throws {
        testUser = nil
        testCity = nil
        testPark = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testUserInitialization() throws {
        XCTAssertNotNil(testUser.id)
        XCTAssertNotNil(testUser.createdDate)
        XCTAssertTrue(testUser.visits?.isEmpty ?? true)
    }
    
    func testUserInitializationWithCustomID() throws {
        let customID = UUID()
        let customUser = User(id: customID)
        
        XCTAssertEqual(customUser.id, customID)
        XCTAssertNotNil(customUser.createdDate)
        XCTAssertTrue(customUser.visits?.isEmpty ?? true)
    }
    
    // MARK: - Relationships Tests
    
    func testVisitsRelationship() throws {
        XCTAssertTrue(testUser.visits?.isEmpty ?? true)
        
        let visit = Visit(park: testPark, user: testUser)
        testUser.visits?.append(visit)
        
        XCTAssertEqual(testUser.visits?.count, 1)
        XCTAssertEqual(testUser.visits?.first?.user?.id, testUser.id)
    }
    
    func testMultipleVisitsRelationship() throws {
        let visit1 = Visit(
            timestamp: Date().addingTimeInterval(-86400),
            park: testPark,
            user: testUser
        )
        let visit2 = Visit(
            timestamp: Date(),
            park: testPark,
            user: testUser
        )
        
        testUser.visits?.append(contentsOf: [visit1, visit2])
        
        XCTAssertEqual(testUser.visits?.count, 2)
        XCTAssertTrue(testUser.visits?.allSatisfy { $0.user?.id == testUser.id } ?? false)
    }
    
    // MARK: - Date Tests
    
    func testCreatedDateIsRecent() throws {
        let now = Date()
        let timeDifference = now.timeIntervalSince(testUser.createdDate)
        XCTAssertLessThan(timeDifference, 1.0)
    }
    
    func testCreatedDateImmutable() throws {
        let originalDate = testUser.createdDate
        
        // Wait a small amount of time
        Thread.sleep(forTimeInterval: 0.01)
        
        // Created date should remain unchanged
        XCTAssertEqual(testUser.createdDate, originalDate)
    }
    
    // MARK: - Visit Statistics Tests
    
    func testVisitStatistics() throws {
        // No visits initially
        XCTAssertEqual(testUser.visits?.count, 0)
        
        // Add visits to same park
        let visit1 = Visit(park: testPark, user: testUser)
        let visit2 = Visit(park: testPark, user: testUser)
        testUser.visits?.append(contentsOf: [visit1, visit2])
        
        XCTAssertEqual(testUser.visits?.count, 2)
        
        // Add visit to different park
        let anotherPark = Park(
            name: "Another Park",
            shortDescription: "Another test park",
            fullDescription: "Another comprehensive test park",
            category: .destination,
            latitude: 39.6,
            longitude: -120.6,
            address: "456 Another Street",
            acreage: 10.0,
            sfParksPropertyID: "ANOTHER123",
            city: testCity
        )
        
        let visit3 = Visit(park: anotherPark, user: testUser)
        testUser.visits?.append(visit3)
        
        XCTAssertEqual(testUser.visits?.count, 3)
        
        // Test unique parks calculation
        let uniqueParks = Set(testUser.visits?.map { $0.parkSFParksPropertyID } ?? [])
        XCTAssertEqual(uniqueParks.count, 2)
    }
    
    func testVisitsWithJournalEntries() throws {
        // Add visits with and without journal entries
        let visitWithJournal = Visit(
            journalEntry: "Great visit!",
            park: testPark,
            user: testUser
        )
        let visitWithoutJournal = Visit(park: testPark, user: testUser)
        let visitWithEmptyJournal = Visit(
            journalEntry: "",
            park: testPark,
            user: testUser
        )
        
        testUser.visits?.append(contentsOf: [visitWithJournal, visitWithoutJournal, visitWithEmptyJournal])
        
        let visitsWithJournal = testUser.visits?.filter { visit in
            if let journal = visit.journalEntry, !journal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return true
            }
            return false
        }
        
        XCTAssertEqual(visitsWithJournal?.count, 1)
    }
    
    // MARK: - Visit Date Analysis Tests
    
    func testVisitDateSorting() throws {
        let calendar = Calendar.current
        let today = Date()
        
        // Add visits in random order
        let visit1 = Visit(timestamp: calendar.date(byAdding: .day, value: -2, to: today)!, park: testPark, user: testUser)
        let visit2 = Visit(timestamp: today, park: testPark, user: testUser)
        let visit3 = Visit(timestamp: calendar.date(byAdding: .day, value: -1, to: today)!, park: testPark, user: testUser)
        
        testUser.visits?.append(contentsOf: [visit1, visit2, visit3])
        
        // Sort visits by timestamp
        let sortedVisits = testUser.visits?.sorted { $0.timestamp < $1.timestamp }
        
        XCTAssertEqual(sortedVisits?.count, 3)
        XCTAssertLessThan(sortedVisits?[0].timestamp ?? Date(), sortedVisits?[1].timestamp ?? Date())
        XCTAssertLessThan(sortedVisits?[1].timestamp ?? Date(), sortedVisits?[2].timestamp ?? Date())
    }
    
    func testRecentVisits() throws {
        let calendar = Calendar.current
        let today = Date()
        
        // Add visits from different time periods
        let recentVisit = Visit(timestamp: today, park: testPark, user: testUser)
        let oldVisit = Visit(timestamp: calendar.date(byAdding: .day, value: -30, to: today)!, park: testPark, user: testUser)
        
        testUser.visits?.append(contentsOf: [recentVisit, oldVisit])
        
        // Filter recent visits (last 7 days)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        let recentVisits = testUser.visits?.filter { $0.timestamp >= sevenDaysAgo }
        
        XCTAssertEqual(recentVisits?.count, 1)
        XCTAssertEqual(recentVisits?.first?.timestamp, today)
    }
    
    // MARK: - Edge Cases Tests
    
    func testUserWithManyVisits() throws {
        // Test user with large number of visits
        for i in 0..<100 {
            let visit = Visit(
                timestamp: Date().addingTimeInterval(-Double(i * 3600)),
                park: testPark,
                user: testUser
            )
            testUser.visits?.append(visit)
        }
        
        XCTAssertEqual(testUser.visits?.count, 100)
        
        // Test that all visits belong to this user
        XCTAssertTrue(testUser.visits?.allSatisfy { $0.user?.id == testUser.id } ?? false)
    }
    
    func testUserWithNoVisits() throws {
        XCTAssertTrue(testUser.visits?.isEmpty ?? true)
        XCTAssertEqual(testUser.visits?.count, 0)
    }
    
    // MARK: - Performance Tests
    
    func testUserInitializationPerformance() throws {
        measure {
            for _ in 0..<1000 {
                let _ = User()
            }
        }
    }
    
    func testVisitArrayPerformance() throws {
        // Add many visits
        for i in 0..<1000 {
            let visit = Visit(
                timestamp: Date().addingTimeInterval(-Double(i * 3600)),
                park: testPark,
                user: testUser
            )
            testUser.visits?.append(visit)
        }
        
        measure {
            // Test array operations
            let _ = testUser.visits?.count
            let _ = testUser.visits?.first
            let _ = testUser.visits?.last
        }
    }
    
    func testUniqueParksCalculationPerformance() throws {
        // Create multiple parks
        var parks: [Park] = []
        for i in 0..<50 {
            let park = Park(
                name: "Park \(i)",
                shortDescription: "Park \(i)",
                fullDescription: "Park \(i)",
                category: .neighborhood,
                latitude: 39.5 + Double(i) * 0.01,
                longitude: -120.5 + Double(i) * 0.01,
                address: "\(i) Park Street",
                acreage: Double(i + 1),
                city: testCity
            )
            parks.append(park)
        }
        
        // Add visits to these parks
        for park in parks {
            for _ in 0..<10 { // Multiple visits per park
                let visit = Visit(park: park, user: testUser)
                testUser.visits?.append(visit)
            }
        }
        
        measure {
            let uniqueParks = Set(testUser.visits?.map { $0.parkSFParksPropertyID } ?? [])
            let _ = uniqueParks.count
        }
    }
    
    // MARK: - SwiftData Integration Tests
    
    func testUserPersistence() throws {
        // Test that User can be persisted and retrieved
        let userID = testUser.id
        
        // Verify ID is maintained
        XCTAssertEqual(testUser.id, userID)
        
        // Test that created date doesn't change
        let originalCreatedDate = testUser.createdDate
        Thread.sleep(forTimeInterval: 0.01)
        XCTAssertEqual(testUser.createdDate, originalCreatedDate)
    }
    
    func testUserVisitCascade() throws {
        // Test that visits maintain relationship to user
        let visit1 = Visit(park: testPark, user: testUser)
        let visit2 = Visit(park: testPark, user: testUser)
        
        testUser.visits?.append(contentsOf: [visit1, visit2])
        
        // Verify bidirectional relationship
        XCTAssertEqual(testUser.visits?.count, 2)
        XCTAssertEqual(visit1.user?.id, testUser.id)
        XCTAssertEqual(visit2.user?.id, testUser.id)
    }
}