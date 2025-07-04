//
//  CityTests.swift
//  FogFernTests
//
//  Created by Claude on 6/29/25.
//

import XCTest
import CoreLocation
@testable import FogFern

final class CityTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var testCity: City!
    
    override func setUpWithError() throws {
        super.setUp()
        testCity = City(
            name: "test_city",
            displayName: "Test City",
            centerLatitude: 39.5,
            centerLongitude: -120.5
        )
    }
    
    override func tearDownWithError() throws {
        testCity = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testCityInitialization() throws {
        XCTAssertEqual(testCity.name, "test_city")
        XCTAssertEqual(testCity.displayName, "Test City")
        XCTAssertEqual(testCity.centerLatitude, 39.5)
        XCTAssertEqual(testCity.centerLongitude, -120.5)
        XCTAssertNotNil(testCity.id)
        XCTAssertNotNil(testCity.createdDate)
        XCTAssertNotNil(testCity.lastUpdated)
    }
    
    func testCityInitializationWithDefaults() throws {
        let defaultCity = City()
        XCTAssertEqual(defaultCity.name, "")
        XCTAssertEqual(defaultCity.displayName, "")
        XCTAssertEqual(defaultCity.centerLatitude, 37.7749) // San Francisco default
        XCTAssertEqual(defaultCity.centerLongitude, -122.4194) // San Francisco default
    }
    
    // MARK: - Coordinate and Location Tests
    
    func testCenterCoordinate() throws {
        let coordinate = testCity.centerCoordinate
        XCTAssertEqual(coordinate.latitude, 39.5, accuracy: 0.001)
        XCTAssertEqual(coordinate.longitude, -120.5, accuracy: 0.001)
    }
    
    // MARK: - Parks Relationship Tests
    
    func testParksRelationship() throws {
        XCTAssertNotNil(testCity.parks)
        XCTAssertTrue(testCity.parks?.isEmpty ?? true)
    }
    
    // MARK: - Date Tests
    
    func testCreatedDateIsRecent() throws {
        let now = Date()
        let timeDifference = now.timeIntervalSince(testCity.createdDate)
        XCTAssertLessThan(timeDifference, 1.0)
    }
    
    func testLastUpdatedIsRecent() throws {
        let now = Date()
        let timeDifference = now.timeIntervalSince(testCity.lastUpdated)
        XCTAssertLessThan(timeDifference, 1.0)
    }
    
    // MARK: - Static San Francisco Tests
    
    func testSanFranciscoStaticCity() throws {
        let sfCity = City.sanFrancisco
        XCTAssertEqual(sfCity.name, "san_francisco")
        XCTAssertEqual(sfCity.displayName, "San Francisco")
        XCTAssertEqual(sfCity.centerLatitude, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(sfCity.centerLongitude, -122.4194, accuracy: 0.0001)
        XCTAssertNotNil(sfCity.id)
    }
    
    func testSanFranciscoCoordinate() throws {
        let sfCity = City.sanFrancisco
        let coordinate = sfCity.centerCoordinate
        XCTAssertEqual(coordinate.latitude, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(coordinate.longitude, -122.4194, accuracy: 0.0001)
    }
    
    // MARK: - Field Validation Tests
    
    func testCityNameAndDisplayNameDifferences() throws {
        // Test that name and displayName serve different purposes
        let testCases = [
            ("san_francisco", "San Francisco"),
            ("new_york", "New York City"),
            ("los_angeles", "Los Angeles"),
            ("test_city", "Test City with Special Characters!")
        ]
        
        for (name, displayName) in testCases {
            let city = City(
                name: name,
                displayName: displayName,
                centerLatitude: 37.0,
                centerLongitude: -122.0
            )
            XCTAssertEqual(city.name, name)
            XCTAssertEqual(city.displayName, displayName)
            XCTAssertNotEqual(city.name, city.displayName) // They should be different
        }
    }
    
    func testCityNameConsistencyForDatabaseQueries() throws {
        // Test that name field is suitable for database queries (lowercase, underscores)
        let dbFriendlyNames = [
            "san_francisco",
            "new_york",
            "los_angeles",
            "chicago",
            "test_city_123"
        ]
        
        for name in dbFriendlyNames {
            let city = City(
                name: name,
                displayName: "Display Name",
                centerLatitude: 37.0,
                centerLongitude: -122.0
            )
            
            // Verify name is suitable for database operations
            XCTAssertFalse(city.name.contains(" "))
            XCTAssertFalse(city.name.contains("'"))
            XCTAssertFalse(city.name.contains("\""))
            XCTAssertEqual(city.name, name.lowercased())
        }
    }
    
    func testCityWithUnicodeDisplayName() throws {
        let unicodeCity = City(
            name: "unicode_test",
            displayName: "Tëst Çîty 北京",
            centerLatitude: 39.9,
            centerLongitude: 116.4
        )
        XCTAssertEqual(unicodeCity.displayName, "Tëst Çîty 北京")
        XCTAssertEqual(unicodeCity.name, "unicode_test")
    }
    
    // MARK: - Edge Cases Tests
    
    func testCityWithEmptyName() throws {
        let emptyCity = City(
            name: "",
            displayName: "Empty Name City",
            centerLatitude: 40.0,
            centerLongitude: -120.0
        )
        XCTAssertEqual(emptyCity.name, "")
        XCTAssertEqual(emptyCity.displayName, "Empty Name City")
    }
    
    func testCityWithExtremeCoordinates() throws {
        let extremeCity = City(
            name: "extreme",
            displayName: "Extreme City",
            centerLatitude: 90.0,
            centerLongitude: 180.0
        )
        XCTAssertEqual(extremeCity.centerLatitude, 90.0)
        XCTAssertEqual(extremeCity.centerLongitude, 180.0)
    }
    
    // MARK: - Performance Tests
    
    func testCityInitializationPerformance() throws {
        measure {
            for _ in 0..<1000 {
                let _ = City(
                    name: "performance_test",
                    displayName: "Performance Test City",
                    centerLatitude: 40.0,
                    centerLongitude: -120.0
                )
            }
        }
    }
    
    func testCenterCoordinatePerformance() throws {
        measure {
            for _ in 0..<10000 {
                let _ = testCity.centerCoordinate
            }
        }
    }
}
