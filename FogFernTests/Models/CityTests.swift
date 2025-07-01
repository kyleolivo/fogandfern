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
