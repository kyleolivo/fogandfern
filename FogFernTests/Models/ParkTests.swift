//
//  ParkTests.swift
//  FogFernTests
//
//  Created by Claude on 6/29/25.
//

import XCTest
import CoreLocation
@testable import FogFern

final class ParkTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var testCity: City!
    var testPark: Park!
    
    override func setUpWithError() throws {
        super.setUp()
        
        testCity = City(
            name: "test_city",
            displayName: "Test City",
            centerLatitude: 39.5,
            centerLongitude: -120.5
        )
        
        testPark = Park(
            name: "Test Park",
            shortDescription: "A beautiful test park",
            fullDescription: "A comprehensive description of our test park with many amenities.",
            category: .neighborhood,
            latitude: 39.5,
            longitude: -120.5,
            address: "123 Test Street, Test City",
            acreage: 5.5,
            city: testCity
        )
    }
    
    override func tearDownWithError() throws {
        testPark = nil
        testCity = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testParkInitialization() throws {
        XCTAssertEqual(testPark.name, "Test Park")
        XCTAssertEqual(testPark.shortDescription, "A beautiful test park")
        XCTAssertEqual(testPark.fullDescription, "A comprehensive description of our test park with many amenities.")
        XCTAssertEqual(testPark.category, .neighborhood)
        XCTAssertEqual(testPark.latitude, 39.5)
        XCTAssertEqual(testPark.longitude, -120.5)
        XCTAssertEqual(testPark.address, "123 Test Street, Test City")
        XCTAssertEqual(testPark.acreage, 5.5)
        XCTAssertTrue(testPark.isActive)
        // isFeatured property removed for CloudKit compatibility
        XCTAssertNotNil(testPark.id)
        XCTAssertNotNil(testPark.createdDate)
        XCTAssertNotNil(testPark.lastUpdated)
    }
    
    func testParkInitializationWithOptionalParameters() throws {
        let parkWithOptionals = Park(
            name: "Full Feature Park",
            shortDescription: "Short desc",
            fullDescription: "Full desc",
            category: .destination,
            latitude: 40.0,
            longitude: -121.0,
            address: "456 Park Avenue",
            neighborhood: "Test Neighborhood",
            zipCode: "12345",
            acreage: 100.0,
            sfParksPropertyID: "SF123",
            city: testCity
        )
        
        XCTAssertEqual(parkWithOptionals.neighborhood, "Test Neighborhood")
        XCTAssertEqual(parkWithOptionals.zipCode, "12345")
        XCTAssertEqual(parkWithOptionals.sfParksPropertyID, "SF123")
    }
    
    // MARK: - Park Category Tests
    
    func testParkCategoryEnum() throws {
        let categories = ParkCategory.allCases
        XCTAssertTrue(categories.contains(.destination))
        XCTAssertTrue(categories.contains(.neighborhood))
        XCTAssertTrue(categories.contains(.mini))
        XCTAssertTrue(categories.contains(.plaza))
        XCTAssertTrue(categories.contains(.garden))
    }
    
    func testParkCategoryDisplayNames() throws {
        XCTAssertEqual(ParkCategory.destination.displayName, "Major Parks")
        XCTAssertEqual(ParkCategory.neighborhood.displayName, "Neighborhood Parks")
        XCTAssertEqual(ParkCategory.mini.displayName, "Mini Parks")
        XCTAssertEqual(ParkCategory.plaza.displayName, "Civic Plazas")
        XCTAssertEqual(ParkCategory.garden.displayName, "Community Gardens")
    }
    
    func testParkCategorySystemImages() throws {
        XCTAssertEqual(ParkCategory.destination.systemImageName, "star.fill")
        XCTAssertEqual(ParkCategory.neighborhood.systemImageName, "house.fill")
        XCTAssertEqual(ParkCategory.mini.systemImageName, "circle.fill")
        XCTAssertEqual(ParkCategory.plaza.systemImageName, "building.2.fill")
        XCTAssertEqual(ParkCategory.garden.systemImageName, "leaf.fill")
    }
    
    func testParkCategoryAllCases() throws {
        let allCategories = ParkCategory.allCases
        XCTAssertEqual(allCategories.count, 5)
        XCTAssertTrue(allCategories.contains(.destination))
        XCTAssertTrue(allCategories.contains(.neighborhood))
        XCTAssertTrue(allCategories.contains(.mini))
        XCTAssertTrue(allCategories.contains(.plaza))
        XCTAssertTrue(allCategories.contains(.garden))
    }
    
    func testParkCategoryIsShownByDefault() throws {
        XCTAssertTrue(ParkCategory.destination.isShownByDefault)
        XCTAssertFalse(ParkCategory.neighborhood.isShownByDefault)
        XCTAssertFalse(ParkCategory.mini.isShownByDefault)
    }
    
    // MARK: - Park Size Tests
    
    func testParkSizeEnum() throws {
        let sizes = ParkSize.allCases
        XCTAssertEqual(sizes.count, 5)
        XCTAssertTrue(sizes.contains(.pocket))
        XCTAssertTrue(sizes.contains(.small))
        XCTAssertTrue(sizes.contains(.medium))
        XCTAssertTrue(sizes.contains(.large))
        XCTAssertTrue(sizes.contains(.massive))
    }
    
    func testParkSizeDisplayNames() throws {
        XCTAssertEqual(ParkSize.pocket.displayName, "Pocket Park")
        XCTAssertEqual(ParkSize.small.displayName, "Small Park")
        XCTAssertEqual(ParkSize.medium.displayName, "Medium Park")
        XCTAssertEqual(ParkSize.large.displayName, "Large Park")
        XCTAssertEqual(ParkSize.massive.displayName, "Major Park")
    }
    
    func testParkSizeCategorization() throws {
        XCTAssertEqual(ParkSize.categorize(acres: 0.5), .pocket)
        XCTAssertEqual(ParkSize.categorize(acres: 2.0), .small)
        XCTAssertEqual(ParkSize.categorize(acres: 10.0), .medium)
        XCTAssertEqual(ParkSize.categorize(acres: 50.0), .large)
        XCTAssertEqual(ParkSize.categorize(acres: 150.0), .massive)
    }
    
    func testParkSizeCategorializationBoundaries() throws {
        XCTAssertEqual(ParkSize.categorize(acres: 0.99), .pocket)
        XCTAssertEqual(ParkSize.categorize(acres: 1.0), .small)
        XCTAssertEqual(ParkSize.categorize(acres: 4.99), .small)
        XCTAssertEqual(ParkSize.categorize(acres: 5.0), .medium)
        XCTAssertEqual(ParkSize.categorize(acres: 19.99), .medium)
        XCTAssertEqual(ParkSize.categorize(acres: 20.0), .large)
        XCTAssertEqual(ParkSize.categorize(acres: 99.99), .large)
        XCTAssertEqual(ParkSize.categorize(acres: 100.0), .massive)
    }
    
    func testParkSizeAutoCalculation() throws {
        XCTAssertEqual(testPark.size, .medium) // 5.5 acres
        
        let smallPark = Park(
            name: "Small Park",
            shortDescription: "Small",
            fullDescription: "Small park",
            category: .mini,
            latitude: 39.0,
            longitude: -120.0,
            address: "Small St",
            acreage: 2.0,
            city: testCity
        )
        XCTAssertEqual(smallPark.size, .small)
    }
    
    // MARK: - Location and Coordinate Tests
    
    func testParkCoordinate() throws {
        let coordinate = testPark.coordinate
        XCTAssertEqual(coordinate.latitude, 39.5, accuracy: 0.001)
        XCTAssertEqual(coordinate.longitude, -120.5, accuracy: 0.001)
    }
    
    func testParkLocation() throws {
        let location = testPark.location
        XCTAssertEqual(location.coordinate.latitude, 39.5, accuracy: 0.001)
        XCTAssertEqual(location.coordinate.longitude, -120.5, accuracy: 0.001)
    }
    
    func testDistanceCalculation() throws {
        let userLocation = CLLocation(latitude: 39.6, longitude: -120.6)
        let distance = testPark.distance(from: userLocation)
        
        // Distance should be reasonable (in meters)
        XCTAssertGreaterThan(distance, 0)
        XCTAssertLessThan(distance, 50000) // Less than 50km
    }
    
    func testFormattedDistance() throws {
        let nearbyLocation = CLLocation(latitude: 39.501, longitude: -120.501)
        let formattedDistance = testPark.formattedDistance(from: nearbyLocation)
        XCTAssertTrue(formattedDistance.contains("mi"))
        
        let farLocation = CLLocation(latitude: 40.0, longitude: -121.0)
        let formattedFarDistance = testPark.formattedDistance(from: farLocation)
        XCTAssertTrue(formattedFarDistance.contains("mi"))
    }
    
    func testFormattedDistanceFormats() throws {
        // Test very close distance (< 0.1 mi)
        let veryCloseLocation = CLLocation(latitude: 39.5001, longitude: -120.5001)
        let veryCloseDistance = testPark.formattedDistance(from: veryCloseLocation)
        XCTAssertEqual(veryCloseDistance, "< 0.1 mi")
        
        // Test medium distance (between 0.1 and 1.0 miles to ensure decimal formatting)
        let mediumLocation = CLLocation(latitude: 39.51, longitude: -120.51)
        let mediumDistance = testPark.formattedDistance(from: mediumLocation)
        XCTAssertTrue(mediumDistance.contains(".") && mediumDistance.contains("mi"))
    }
    
    // MARK: - Formatting Tests
    
    func testFormattedAcreage() throws {
        // Test small acreage with decimal
        let smallPark = Park(
            name: "Small",
            shortDescription: "Small",
            fullDescription: "Small",
            category: .mini,
            latitude: 39.0,
            longitude: -120.0,
            address: "Small St",
            acreage: 0.5,
            city: testCity
        )
        XCTAssertEqual(smallPark.formattedAcreage, "0.5 acres")
        
        // Test large acreage without decimal
        let largePark = Park(
            name: "Large",
            shortDescription: "Large",
            fullDescription: "Large",
            category: .destination,
            latitude: 39.0,
            longitude: -120.0,
            address: "Large St",
            acreage: 15.0,
            city: testCity
        )
        XCTAssertEqual(largePark.formattedAcreage, "15 acres")
    }
    
    func testImageName() throws {
        XCTAssertEqual(testPark.imageName, "test-park")
        
        let complexNamePark = Park(
            name: "Golden Gate Park & Recreation Area",
            shortDescription: "Complex",
            fullDescription: "Complex",
            category: .destination,
            latitude: 39.0,
            longitude: -120.0,
            address: "Complex St",
            acreage: 100.0,
            city: testCity
        )
        XCTAssertEqual(complexNamePark.imageName, "golden-gate-park-and-recreation-area")
    }
    
    func testImageNameSpecialCharacters() throws {
        let specialPark = Park(
            name: "St. Mary's Park/Garden",
            shortDescription: "Special",
            fullDescription: "Special",
            category: .garden,
            latitude: 39.0,
            longitude: -120.0,
            address: "Special St",
            acreage: 2.0,
            city: testCity
        )
        XCTAssertEqual(specialPark.imageName, "st-marys-park-garden")
    }
    
    // MARK: - Relationships Tests
    
    func testCityRelationship() throws {
        XCTAssertEqual(testPark.city?.id, testCity.id)
        XCTAssertEqual(testPark.city?.name, testCity.name)
    }
    
    // Visits relationship removed - visits are now accessed through queries
    
    // MARK: - Property Validation Tests
    
    func testDefaultValues() throws {
        XCTAssertTrue(testPark.isActive)
        // Properties removed for CloudKit compatibility:
        // - isFeatured
        // - featuredRank  
        // - accessibilityFeatures
        // - imageURLs
        // - primaryImageURL
    }
    
    func testCreatedDateIsRecent() throws {
        let now = Date()
        let timeDifference = now.timeIntervalSince(testPark.createdDate)
        XCTAssertLessThan(timeDifference, 1.0)
    }
    
    func testLastUpdatedIsRecent() throws {
        let now = Date()
        let timeDifference = now.timeIntervalSince(testPark.lastUpdated)
        XCTAssertLessThan(timeDifference, 1.0)
    }
    
    // MARK: - Edge Cases Tests
    
    func testParkWithZeroAcreage() throws {
        let zeroPark = Park(
            name: "Zero Park",
            shortDescription: "Zero",
            fullDescription: "Zero",
            category: .mini,
            latitude: 39.0,
            longitude: -120.0,
            address: "Zero St",
            acreage: 0.0,
            city: testCity
        )
        XCTAssertEqual(zeroPark.size, .pocket)
        XCTAssertEqual(zeroPark.formattedAcreage, "0.0 acres")
    }
    
    func testParkWithExtremeCoordinates() throws {
        let extremePark = Park(
            name: "Extreme Park",
            shortDescription: "Extreme",
            fullDescription: "Extreme",
            category: .destination,
            latitude: 90.0,
            longitude: 180.0,
            address: "Extreme St",
            acreage: 1000000.0,
            city: testCity
        )
        XCTAssertEqual(extremePark.size, .massive)
        XCTAssertEqual(extremePark.coordinate.latitude, 90.0)
        XCTAssertEqual(extremePark.coordinate.longitude, 180.0)
    }
    
    // MARK: - Performance Tests
    
    func testParkInitializationPerformance() throws {
        measure {
            for _ in 0..<1000 {
                let _ = Park(
                    name: "Performance Test Park",
                    shortDescription: "Performance",
                    fullDescription: "Performance test park",
                    category: .neighborhood,
                    latitude: 39.5,
                    longitude: -120.5,
                    address: "Performance St",
                    acreage: 5.0,
                    city: testCity
                )
            }
        }
    }
    
    func testDistanceCalculationPerformance() throws {
        let testLocation = CLLocation(latitude: 40.0, longitude: -121.0)
        
        measure {
            for _ in 0..<10000 {
                let _ = testPark.distance(from: testLocation)
            }
        }
    }
    
    func testFormattedDistancePerformance() throws {
        let testLocation = CLLocation(latitude: 40.0, longitude: -121.0)
        
        measure {
            for _ in 0..<1000 {
                let _ = testPark.formattedDistance(from: testLocation)
            }
        }
    }
}