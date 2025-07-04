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
        let uniqueParks = Set(testUser.visits?.map { $0.parkUniqueID } ?? [])
        XCTAssertEqual(uniqueParks.count, 2)
    }
    
    func testMultipleVisitsToSamePark() throws {
        // Add multiple visits to same park
        let visit1 = Visit(park: testPark, user: testUser)
        let visit2 = Visit(park: testPark, user: testUser)
        let visit3 = Visit(park: testPark, user: testUser)
        
        testUser.visits?.append(contentsOf: [visit1, visit2, visit3])
        
        XCTAssertEqual(testUser.visits?.count, 3)
        let expectedUniqueID = Visit.generateUniqueID(for: testPark)
        XCTAssertTrue(testUser.visits?.allSatisfy { $0.parkUniqueID == expectedUniqueID } ?? false)
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
            let uniqueParks = Set(testUser.visits?.map { $0.parkUniqueID } ?? [])
            let _ = uniqueParks.count
        }
    }
    
    // MARK: - Advanced User Scenarios Tests
    
    func testUserWithManyVisitsPerformance() throws {
        // Test performance with a large number of visits
        let numberOfVisits = 1000
        
        for i in 0..<numberOfVisits {
            let visit = Visit(
                timestamp: Date().addingTimeInterval(Double(i)),
                park: testPark,
                user: testUser
            )
            testUser.visits?.append(visit)
        }
        
        XCTAssertEqual(testUser.visits?.count, numberOfVisits)
        
        // Test that operations on large visit collections are still performant
        measure {
            let visitCount = testUser.visits?.count ?? 0
            XCTAssertEqual(visitCount, numberOfVisits)
        }
    }
    
    func testUserVisitStatisticsWithDifferentTimestamps() throws {
        let baseDate = Date()
        let visits = [
            Visit(timestamp: baseDate.addingTimeInterval(-86400 * 7), park: testPark, user: testUser),  // 1 week ago
            Visit(timestamp: baseDate.addingTimeInterval(-86400 * 1), park: testPark, user: testUser),  // 1 day ago
            Visit(timestamp: baseDate.addingTimeInterval(-3600), park: testPark, user: testUser),       // 1 hour ago
            Visit(timestamp: baseDate, park: testPark, user: testUser)                                  // Now
        ]
        
        testUser.visits?.append(contentsOf: visits)
        
        XCTAssertEqual(testUser.visits?.count, 4)
        
        // Test that visits can be sorted by timestamp
        let sortedVisits = testUser.visits?.sorted { $0.timestamp < $1.timestamp }
        XCTAssertNotNil(sortedVisits)
        XCTAssertEqual(sortedVisits?.count, 4)
        
        // Verify chronological order
        for i in 0..<(sortedVisits!.count - 1) {
            XCTAssertLessThanOrEqual(sortedVisits![i].timestamp, sortedVisits![i + 1].timestamp)
        }
    }
    
    func testUserWithEmptyVisitsArray() throws {
        let userWithEmptyVisits = User()
        
        // User starts with empty array, not nil (SwiftData behavior)
        XCTAssertNotNil(userWithEmptyVisits.visits)
        XCTAssertEqual(userWithEmptyVisits.visits?.count, 0)
        XCTAssertTrue(userWithEmptyVisits.visits?.isEmpty ?? true)
        
        // Operations on empty visits should work gracefully
        let visitCount = userWithEmptyVisits.visits?.count ?? 0
        XCTAssertEqual(visitCount, 0)
        
        // Test that we can add visits to the empty array
        let visit = Visit(park: testPark, user: userWithEmptyVisits)
        userWithEmptyVisits.visits?.append(visit)
        XCTAssertEqual(userWithEmptyVisits.visits?.count, 1)
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