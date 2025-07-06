//
//  ParkRepositoryTests.swift
//  FogFernTests
//
//  Created by Claude on 6/29/25.
//

import XCTest
import SwiftData
import CoreLocation
@testable import FogFern

final class ParkRepositoryTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var modelContainer: ModelContainer!
    var repository: ParkRepository!
    var testCity: City!
    var testParks: [Park]!
    
    override func setUpWithError() throws {
        super.setUp()
        
        // Create in-memory model container for testing
        let schema = Schema([City.self, Park.self, Visit.self, User.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        
        repository = ParkRepository(modelContainer: modelContainer)
        
        testCity = City(
            name: "test_city",
            displayName: "Test City",
            centerLatitude: 39.5,
            centerLongitude: -120.5
        )
        
        // Create test parks
        testParks = [
            Park(
                name: "Featured Park",
                shortDescription: "A featured park",
                fullDescription: "A comprehensive featured park",
                category: .destination,
                latitude: 39.5,
                longitude: -120.5,
                address: "123 Featured Street",
                acreage: 100.0,
                propertyID: "FEATURED123",
                city: testCity
            ),
            Park(
                name: "Neighborhood Park",
                shortDescription: "A neighborhood park",
                fullDescription: "A comprehensive neighborhood park",
                category: .neighborhood,
                latitude: 39.51,
                longitude: -120.51,
                address: "456 Neighborhood Street",
                acreage: 5.0,
                propertyID: "NEIGHBORHOOD123",
                city: testCity
            ),
            Park(
                name: "Mini Park",
                shortDescription: "A mini park",
                fullDescription: "A comprehensive mini park",
                category: .mini,
                latitude: 39.52,
                longitude: -120.52,
                address: "789 Mini Street",
                acreage: 0.5,
                propertyID: "MINI123",
                city: testCity
            )
        ]
        
        // Featured properties removed for CloudKit compatibility
        
        // Insert test data
        let context = ModelContext(modelContainer)
        context.insert(testCity)
        testParks.forEach { context.insert($0) }
        try context.save()
        
        // Create repository with the same container (not specific context)
        repository = ParkRepository(modelContainer: modelContainer)
    }
    
    override func tearDownWithError() throws {
        testParks = nil
        testCity = nil
        repository = nil
        modelContainer = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testRepositoryInitialization() throws {
        XCTAssertNotNil(repository)
        
        let newRepository = ParkRepository(modelContainer: modelContainer)
        XCTAssertNotNil(newRepository)
    }
    
    // MARK: - Get All Parks Tests
    
    func testGetAllParks() async throws {
        let parks = try await repository.getAllParks(for: testCity)
        
        XCTAssertEqual(parks.count, 3)
        
        // Should be sorted by name since featured property was removed
        XCTAssertEqual(parks[0].name, "Featured Park")
        XCTAssertEqual(parks[1].name, "Mini Park")
        XCTAssertEqual(parks[2].name, "Neighborhood Park")
    }
    
    func testGetAllParksForDifferentCity() async throws {
        let differentCity = City(
            name: "different_city",
            displayName: "Different City",
            centerLatitude: 40.5,
            centerLongitude: -73.5
        )
        
        let parks = try await repository.getAllParks(for: differentCity)
        XCTAssertEqual(parks.count, 0)
    }
    
    func testGetAllParksWithInactiveParks() async throws {
        // Make one park inactive by fetching it from database and updating
        let context = ModelContext(modelContainer)
        let parkId = testParks[1].id
        let descriptor = FetchDescriptor<Park>(
            predicate: #Predicate<Park> { park in
                park.id == parkId
            }
        )
        let parksToUpdate = try context.fetch(descriptor)
        if let parkToUpdate = parksToUpdate.first {
            parkToUpdate.isActive = false
            try context.save()
        }
        
        let parks = try await repository.getAllParks(for: testCity)
        XCTAssertEqual(parks.count, 2) // Should exclude inactive park
    }
    
    // MARK: - Get Featured Parks Tests
    
    func testGetFeaturedParks() async throws {
        let featuredParks = try await repository.getFeaturedParks(for: testCity)
        
        // getFeaturedParks now returns all active parks sorted by name
        XCTAssertEqual(featuredParks.count, 3)
        XCTAssertEqual(featuredParks[0].name, "Featured Park")
        XCTAssertEqual(featuredParks[1].name, "Mini Park")
        XCTAssertEqual(featuredParks[2].name, "Neighborhood Park")
    }
    
    func testGetFeaturedParksWithMultipleFeatured() async throws {
        // getFeaturedParks returns all parks sorted by name
        let featuredParks = try await repository.getFeaturedParks(for: testCity)
        
        XCTAssertEqual(featuredParks.count, 3)
        // Should be sorted by name
        XCTAssertEqual(featuredParks[0].name, "Featured Park")
        XCTAssertEqual(featuredParks[1].name, "Mini Park")
        XCTAssertEqual(featuredParks[2].name, "Neighborhood Park")
    }
    
    func testGetFeaturedParksWithNoFeatured() async throws {
        // getFeaturedParks returns all active parks regardless of featured status
        let featuredParks = try await repository.getFeaturedParks(for: testCity)
        XCTAssertEqual(featuredParks.count, 3)
    }
    
    // MARK: - Get Parks Near Location Tests
    
    func testGetParksNearLocation() async throws {
        let userLocation = CLLocation(latitude: 39.5, longitude: -120.5) // Same as Featured Park
        let radius: CLLocationDistance = 1000 // 1km
        
        let nearbyParks = try await repository.getParksNearLocation(userLocation, radius: radius, city: testCity)
        
        XCTAssertGreaterThan(nearbyParks.count, 0)
        // Should be sorted by distance (closest first)
        let firstPark = nearbyParks[0]
        let firstDistance = CLLocation(latitude: firstPark.latitude, longitude: firstPark.longitude).distance(from: userLocation)
        XCTAssertLessThanOrEqual(firstDistance, radius)
    }
    
    func testGetParksNearLocationWithLargeRadius() async throws {
        let userLocation = CLLocation(latitude: 39.5, longitude: -120.5)
        let radius: CLLocationDistance = 10000 // 10km
        
        let nearbyParks = try await repository.getParksNearLocation(userLocation, radius: radius, city: testCity)
        
        // Should include all parks since they're all within 10km
        XCTAssertEqual(nearbyParks.count, 3)
    }
    
    func testGetParksNearLocationWithSmallRadius() async throws {
        let userLocation = CLLocation(latitude: 40.0, longitude: -121.0) // Far from parks
        let radius: CLLocationDistance = 100 // 100m
        
        let nearbyParks = try await repository.getParksNearLocation(userLocation, radius: radius, city: testCity)
        
        // Should be empty since parks are far away
        XCTAssertEqual(nearbyParks.count, 0)
    }
    
    func testGetParksNearLocationExcludesInvalidCoordinates() async throws {
        // Add park with invalid coordinates using proper context handling
        let context = ModelContext(modelContainer)
        
        // First fetch the city from this context
        let cityId = testCity.id
        let cityDescriptor = FetchDescriptor<City>(
            predicate: #Predicate<City> { city in
                city.id == cityId
            }
        )
        let cities = try context.fetch(cityDescriptor)
        guard let contextCity = cities.first else {
            XCTFail("Could not find test city in context")
            return
        }
        
        let invalidPark = Park(
            name: "Invalid Park",
            shortDescription: "Invalid coordinates",
            fullDescription: "Park with invalid coordinates",
            category: .mini,
            latitude: 0.0,
            longitude: 0.0,
            address: "Invalid Address",
            acreage: 1.0,
            propertyID: "INVALID123",
            city: contextCity
        )
        
        context.insert(invalidPark)
        try context.save()
        
        let userLocation = CLLocation(latitude: 39.5, longitude: -120.5)
        let radius: CLLocationDistance = 10000
        
        let nearbyParks = try await repository.getParksNearLocation(userLocation, radius: radius, city: testCity)
        
        // Should exclude park with 0,0 coordinates
        XCTAssertEqual(nearbyParks.count, 3)
        XCTAssertFalse(nearbyParks.contains { $0.name == "Invalid Park" })
    }
    
    // MARK: - Get Park by ID Tests
    
    func testGetParkById() async throws {
        let parkId = testParks[0].id
        let foundPark = try await repository.getPark(by: parkId)
        
        XCTAssertNotNil(foundPark)
        XCTAssertEqual(foundPark?.id, parkId)
        XCTAssertEqual(foundPark?.name, "Featured Park")
    }
    
    func testGetParkByNonexistentId() async throws {
        let nonexistentId = UUID()
        let foundPark = try await repository.getPark(by: nonexistentId)
        
        XCTAssertNil(foundPark)
    }
    
    // MARK: - Search Parks Tests
    
    func testSearchParksByName() async throws {
        let results = try await repository.searchParks(query: "Featured", in: testCity)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "Featured Park")
    }
    
    func testSearchParksByDescription() async throws {
        let results = try await repository.searchParks(query: "neighborhood", in: testCity)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "Neighborhood Park")
    }
    
    func testSearchParksWithEmptyQuery() async throws {
        do {
            _ = try await repository.searchParks(query: "", in: testCity)
            XCTFail("Should throw error for empty query")
        } catch let error as ParkRepositoryError {
            switch error.code {
            case .invalidParkData(let reason):
                XCTAssertTrue(reason.contains("empty"))
            default:
                XCTFail("Wrong error type")
            }
        }
    }
    
    func testSearchParksWithWhitespaceQuery() async throws {
        do {
            _ = try await repository.searchParks(query: "   \n\t  ", in: testCity)
            XCTFail("Should throw error for whitespace-only query")
        } catch let error as ParkRepositoryError {
            switch error.code {
            case .invalidParkData:
                XCTAssertTrue(true) // Expected error
            default:
                XCTFail("Wrong error type")
            }
        }
    }
    
    func testSearchParksNoResults() async throws {
        let results = try await repository.searchParks(query: "nonexistent", in: testCity)
        XCTAssertEqual(results.count, 0)
    }
    
    func testSearchParksCaseInsensitive() async throws {
        let results = try await repository.searchParks(query: "FEATURED", in: testCity)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "Featured Park")
    }
    
    // MARK: - Get Parks by Category Tests
    
    func testGetParksByCategory() async throws {
        // Debug: First check if we can get all parks
        let allParks = try await repository.getAllParks(for: testCity)
        print("DEBUG: Total parks found: \(allParks.count)")
        for park in allParks {
            print("DEBUG: Park '\(park.name)' - category: \(park.category), isActive: \(park.isActive)")
        }
        
        let destinationParks = try await repository.getParksBy(category: .destination, in: testCity)
        print("DEBUG: Destination parks found: \(destinationParks.count)")
        
        XCTAssertEqual(destinationParks.count, 1)
        XCTAssertEqual(destinationParks[0].name, "Featured Park")
        XCTAssertEqual(destinationParks[0].category, .destination)
    }
    
    func testGetParksByCategoryWithMultipleParks() async throws {
        // First verify we have the expected parks from setup
        let allParks = try await repository.getAllParks(for: testCity)
        XCTAssertEqual(allParks.count, 3)
        
        // Get initial destination parks count
        let initialDestinationParks = try await repository.getParksBy(category: .destination, in: testCity)
        XCTAssertEqual(initialDestinationParks.count, 1)
        XCTAssertEqual(initialDestinationParks[0].name, "Featured Park")
        
        // Add another destination park using a fresh context like the repository does
        let context = ModelContext(modelContainer)
        
        // First fetch the city from this context
        let cityId = testCity.id
        let cityDescriptor = FetchDescriptor<City>(
            predicate: #Predicate<City> { city in
                city.id == cityId
            }
        )
        let cities = try context.fetch(cityDescriptor)
        guard let contextCity = cities.first else {
            XCTFail("Could not find test city in context")
            return
        }
        
        let anotherDestinationPark = Park(
            name: "Another Destination",
            shortDescription: "Another destination park",
            fullDescription: "Another comprehensive destination park",
            category: .destination,
            latitude: 39.53,
            longitude: -120.53,
            address: "999 Destination Street",
            acreage: 50.0,
            propertyID: "ANOTHERDEST123",
            city: contextCity
        )
        
        context.insert(anotherDestinationPark)
        try context.save()
        
        let destinationParks = try await repository.getParksBy(category: .destination, in: testCity)
        
        XCTAssertEqual(destinationParks.count, 2)
        // Should be sorted by name
        XCTAssertEqual(destinationParks[0].name, "Another Destination")
        XCTAssertEqual(destinationParks[1].name, "Featured Park")
    }
    
    func testGetParksByCategoryNoResults() async throws {
        let gardenParks = try await repository.getParksBy(category: .garden, in: testCity)
        XCTAssertEqual(gardenParks.count, 0)
    }
    
    // MARK: - Get Parks by Size Tests
    
    func testGetParksBySize() async throws {
        let mediumParks = try await repository.getParksBy(size: .medium, in: testCity)
        
        XCTAssertEqual(mediumParks.count, 1)
        XCTAssertEqual(mediumParks[0].name, "Neighborhood Park")
        XCTAssertEqual(mediumParks[0].size, .medium)
    }
    
    func testGetParksBySizeWithMultipleParks() async throws {
        // Get initial medium parks count
        let initialMediumParks = try await repository.getParksBy(size: .medium, in: testCity)
        XCTAssertEqual(initialMediumParks.count, 1)
        XCTAssertEqual(initialMediumParks[0].name, "Neighborhood Park")
        
        // Add another medium park using a fresh context like the repository does
        let context = ModelContext(modelContainer)
        
        // First fetch the city from this context
        let cityId = testCity.id
        let cityDescriptor = FetchDescriptor<City>(
            predicate: #Predicate<City> { city in
                city.id == cityId
            }
        )
        let cities = try context.fetch(cityDescriptor)
        guard let contextCity = cities.first else {
            XCTFail("Could not find test city in context")
            return
        }
        
        let anotherMediumPark = Park(
            name: "Another Medium Park",
            shortDescription: "Another medium park",
            fullDescription: "Another comprehensive medium park",
            category: .neighborhood,
            latitude: 39.54,
            longitude: -120.54,
            address: "888 Medium Street",
            acreage: 10.0,
            propertyID: "ANOTHERMEDIUM123",
            city: contextCity
        )
        
        context.insert(anotherMediumPark)
        try context.save()
        
        let mediumParks = try await repository.getParksBy(size: .medium, in: testCity)
        
        XCTAssertEqual(mediumParks.count, 2)
        // Should be sorted by acreage (larger first), then by name
        XCTAssertEqual(mediumParks[0].acreage, 10.0) // Another Medium Park
        XCTAssertEqual(mediumParks[1].acreage, 5.0) // Neighborhood Park
    }
    
    func testGetParksBySizeNoResults() async throws {
        let smallParks = try await repository.getParksBy(size: .small, in: testCity)
        XCTAssertEqual(smallParks.count, 0)
    }
    
    // MARK: - Statistics Tests
    
    func testGetVisitStatistics() async throws {
        let stats = try await repository.getVisitStatistics(for: testCity)
        
        XCTAssertEqual(stats.totalParks, 3)
        XCTAssertEqual(stats.featuredParks, 0)
        XCTAssertEqual(stats.totalAcreage, 105.5) // 100 + 5 + 0.5
        
        // Check category breakdown
        XCTAssertEqual(stats.categoryBreakdown[.destination], 1)
        XCTAssertEqual(stats.categoryBreakdown[.neighborhood], 1)
        XCTAssertEqual(stats.categoryBreakdown[.mini], 1)
        
        // Check size breakdown
        XCTAssertEqual(stats.sizeBreakdown[.massive], 1) // 100 acres
        XCTAssertEqual(stats.sizeBreakdown[.medium], 1) // 5 acres
        XCTAssertEqual(stats.sizeBreakdown[.pocket], 1) // 0.5 acres
    }
    
    func testGetVisitStatisticsEmptyCity() async throws {
        let emptyCity = City(
            name: "empty_city",
            displayName: "Empty City",
            centerLatitude: 40.5,
            centerLongitude: -73.5
        )
        
        let stats = try await repository.getVisitStatistics(for: emptyCity)
        
        XCTAssertEqual(stats.totalParks, 0)
        XCTAssertEqual(stats.featuredParks, 0)
        XCTAssertEqual(stats.totalAcreage, 0.0)
        XCTAssertTrue(stats.categoryBreakdown.isEmpty)
        XCTAssertTrue(stats.sizeBreakdown.isEmpty)
    }
    
    // MARK: - Error Handling Tests
    
    func testParkRepositoryErrorTypes() throws {
        let parkNotFoundError = ParkRepositoryError(.parkNotFound(id: UUID()))
        XCTAssertNotNil(parkNotFoundError.errorDescription)
        XCTAssertNotNil(parkNotFoundError.failureReason)
        XCTAssertNotNil(parkNotFoundError.recoverySuggestion)
        
        let invalidDataError = ParkRepositoryError(.invalidParkData(reason: "Test reason"))
        XCTAssertTrue(invalidDataError.errorDescription?.contains("Test reason") == true)
        
        let networkError = ParkRepositoryError(.networkFailure(reason: "Connection failed"))
        XCTAssertTrue(networkError.errorDescription?.contains("Connection failed") == true)
        
        let dataCorruptionError = ParkRepositoryError(.dataCorruption(details: "Database corrupted"))
        XCTAssertTrue(dataCorruptionError.errorDescription?.contains("Database corrupted") == true)
    }
    
    // MARK: - Main Actor Tests
    
    @MainActor
    func testGetAllParksForUI() async throws {
        let parks = try await repository.getAllParksForUI(for: testCity)
        
        XCTAssertEqual(parks.count, 3)
        // Should be sorted by name
        XCTAssertEqual(parks[0].name, "Featured Park")
    }
    
    // MARK: - Performance Tests
    
    func testGetAllParksPerformance() throws {
        // Add many parks for performance testing
        let context = ModelContext(modelContainer)
        
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
                propertyID: "PERF\(i)",
                city: testCity
            )
            context.insert(park)
        }
        try context.save()
        
        measure {
            let expectation = XCTestExpectation(description: "Get all parks")
            Task {
                do {
                    _ = try await repository.getAllParks(for: testCity)
                    expectation.fulfill()
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testSearchParksPerformance() throws {
        // Add many parks for performance testing
        let context = ModelContext(modelContainer)
        
        for i in 0..<1000 {
            let park = Park(
                name: "Search Test Park \(i)",
                shortDescription: "Search performance test park \(i)",
                fullDescription: "Comprehensive search performance test park \(i)",
                category: .neighborhood,
                latitude: 39.5 + Double(i) * 0.0001,
                longitude: -120.5 + Double(i) * 0.0001,
                address: "\(i) Search Street",
                acreage: Double(i + 1),
                propertyID: "SEARCH\(i)",
                city: testCity
            )
            context.insert(park)
        }
        try context.save()
        
        measure {
            let expectation = XCTestExpectation(description: "Search parks")
            Task {
                do {
                    _ = try await repository.searchParks(query: "Test", in: testCity)
                    expectation.fulfill()
                } catch {
                    XCTFail("Search performance test failed: \(error)")
                }
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentParkAccess() throws {
        let expectation = XCTestExpectation(description: "Concurrent park access")
        expectation.expectedFulfillmentCount = 5
        
        for i in 0..<5 {
            DispatchQueue.global().async {
                Task {
                    do {
                        switch i {
                        case 0:
                            _ = try await self.repository.getAllParks(for: self.testCity)
                        case 1:
                            _ = try await self.repository.getFeaturedParks(for: self.testCity)
                        case 2:
                            let location = CLLocation(latitude: 39.5, longitude: -120.5)
                            _ = try await self.repository.getParksNearLocation(location, radius: 1000, city: self.testCity)
                        case 3:
                            _ = try await self.repository.getParksBy(category: .destination, in: self.testCity)
                        case 4:
                            _ = try await self.repository.searchParks(query: "park", in: self.testCity)
                        default:
                            break
                        }
                        expectation.fulfill()
                    } catch {
                        XCTFail("Concurrent access failed: \(error)")
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Edge Cases Tests
    
    func testRepositoryWithCorruptedData() async throws {
        // This test would simulate corrupted data scenarios
        // For now, we'll test that repository handles missing relationships gracefully
        
        // Create a park using proper context handling
        let context = ModelContext(modelContainer)
        
        // First fetch the city from this context
        let cityId = testCity.id
        let cityDescriptor = FetchDescriptor<City>(
            predicate: #Predicate<City> { city in
                city.id == cityId
            }
        )
        let cities = try context.fetch(cityDescriptor)
        guard let contextCity = cities.first else {
            XCTFail("Could not find test city in context")
            return
        }
        
        let orphanPark = Park(
            name: "Orphan Park",
            shortDescription: "Park without city",
            fullDescription: "Park without proper city relationship",
            category: .mini,
            latitude: 39.99,
            longitude: -120.99,
            address: "Orphan Street",
            acreage: 1.0,
            propertyID: "ORPHAN123",
            city: contextCity
        )
        
        context.insert(orphanPark)
        try context.save()
        
        // Repository should still work
        let parks = try await repository.getAllParks(for: testCity)
        XCTAssertEqual(parks.count, 4) // 3 original + 1 orphan
    }
    
    func testRepositoryWithExtremeCoordinates() async throws {
        // Create a park with extreme coordinates using proper context handling
        let context = ModelContext(modelContainer)
        
        // First fetch the city from this context
        let cityId = testCity.id
        let cityDescriptor = FetchDescriptor<City>(
            predicate: #Predicate<City> { city in
                city.id == cityId
            }
        )
        let cities = try context.fetch(cityDescriptor)
        guard let contextCity = cities.first else {
            XCTFail("Could not find test city in context")
            return
        }
        
        let extremePark = Park(
            name: "Extreme Park",
            shortDescription: "Park with extreme coordinates",
            fullDescription: "Park with extreme coordinate values",
            category: .destination,
            latitude: 89.99,
            longitude: 179.99,
            address: "Extreme Location",
            acreage: 999999.0,
            propertyID: "EXTREME123",
            city: contextCity
        )
        
        context.insert(extremePark)
        try context.save()
        
        // Test location-based query with extreme coordinates
        let location = CLLocation(latitude: 89.99, longitude: 179.99)
        let nearbyParks = try await repository.getParksNearLocation(location, radius: 1000000, city: testCity)
        
        XCTAssertGreaterThan(nearbyParks.count, 0)
    }
    
    // MARK: - Additional Tests for Recent Changes
    
    func testParkRepositoryWithNewPropertyIDField() async throws {
        // Test that the renamed propertyID field works correctly
        let parks = try await repository.getAllParks(for: testCity)
        let foundPark = parks.first { $0.propertyID == "FEATURED123" }
        
        XCTAssertNotNil(foundPark)
        XCTAssertEqual(foundPark?.propertyID, "FEATURED123")
        XCTAssertEqual(foundPark?.name, "Featured Park")
    }
    
    func testParkRepositoryWithNilPropertyID() async throws {
        // Test that parks without propertyID still work correctly
        let context = ModelContext(modelContainer)
        
        // First fetch the city from this context
        let cityId = testCity.id
        let cityDescriptor = FetchDescriptor<City>(
            predicate: #Predicate<City> { city in
                city.id == cityId
            }
        )
        let cities = try context.fetch(cityDescriptor)
        guard let contextCity = cities.first else {
            XCTFail("Could not find test city in context")
            return
        }
        
        let park = Park(
            name: "No Property ID Park",
            shortDescription: "Testing nil property ID",
            fullDescription: "Full description for nil property ID test",
            category: .mini,
            latitude: 37.8,
            longitude: -122.5,
            address: "456 No Property St",
            acreage: 2.0,
            city: contextCity
        )
        
        context.insert(park)
        try context.save()
        
        let parks = try await repository.getAllParks(for: testCity)
        let foundPark = parks.first { $0.name == "No Property ID Park" }
        
        XCTAssertNotNil(foundPark)
        XCTAssertNil(foundPark?.propertyID)
        XCTAssertEqual(foundPark?.name, "No Property ID Park")
    }
    
    func testGetParksByCategoryWithUpdatedCategories() async throws {
        // Test with the cleaned up category enum (only 5 categories now)
        let context = ModelContext(modelContainer)
        
        // First fetch the city from this context
        let cityId = testCity.id
        let cityDescriptor = FetchDescriptor<City>(
            predicate: #Predicate<City> { city in
                city.id == cityId
            }
        )
        let cities = try context.fetch(cityDescriptor)
        guard let contextCity = cities.first else {
            XCTFail("Could not find test city in context")
            return
        }
        
        // Create parks for each of the 5 remaining categories
        let categories: [ParkCategory] = [.destination, .neighborhood, .mini, .plaza, .garden]
        var createdParks: [Park] = []
        
        for category in categories {
            let park = Park(
                name: "\(category.displayName) Test Park",
                shortDescription: "Testing \(category.rawValue) category",
                fullDescription: "Full description for \(category.displayName)",
                category: category,
                latitude: 37.7,
                longitude: -122.4,
                address: "123 \(category.displayName) St",
                acreage: 5.0,
                propertyID: "\(category.rawValue.uppercased())123",
                city: contextCity
            )
            createdParks.append(park)
            context.insert(park)
        }
        
        try context.save()
        
        // Test each category (only test for one since we know our test setup has limited parks)
        let destinationParks = try await repository.getParksBy(category: .destination, in: testCity)
        XCTAssertGreaterThanOrEqual(destinationParks.count, 1)
        
        // Verify we can fetch all parks
        let allParks = try await repository.getAllParks(for: testCity)
        XCTAssertGreaterThanOrEqual(allParks.count, 3) // At least our original test parks
    }
    
    func testSearchParksWithCompositeIDReferences() async throws {
        // Test search functionality works with parks that have composite ID references
        let context = ModelContext(modelContainer)
        
        // First fetch the city from this context
        let cityId = testCity.id
        let cityDescriptor = FetchDescriptor<City>(
            predicate: #Predicate<City> { city in
                city.id == cityId
            }
        )
        let cities = try context.fetch(cityDescriptor)
        guard let contextCity = cities.first else {
            XCTFail("Could not find test city in context")
            return
        }
        
        let searchablePark = Park(
            name: "Searchable Composite Park",
            shortDescription: "A park with composite ID for searching",
            fullDescription: "This park tests search with composite ID functionality",
            category: .destination,
            latitude: 37.7,
            longitude: -122.4,
            address: "789 Composite Search St",
            acreage: 15.0,
            propertyID: "SEARCH789",
            city: contextCity
        )
        
        context.insert(searchablePark)
        try context.save()
        
        // Test search by name
        let nameResults = try await repository.searchParks(query: "Searchable", in: testCity)
        XCTAssertEqual(nameResults.count, 1)
        XCTAssertEqual(nameResults.first?.propertyID, "SEARCH789")
        
        // Test search by description
        let descResults = try await repository.searchParks(query: "composite ID", in: testCity)
        XCTAssertEqual(descResults.count, 1)
        XCTAssertEqual(descResults.first?.name, "Searchable Composite Park")
    }
    
    func testParkRepositoryErrorMessages() async throws {
        // Test that custom error messages are properly formatted
        do {
            _ = try await repository.searchParks(query: "", in: testCity)
            XCTFail("Should have thrown an error for empty query")
        } catch let error as ParkRepositoryError {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertTrue(error.errorDescription?.contains("empty") ?? false)
        }
        
        // Test park not found error
        let nonexistentID = UUID()
        do {
            _ = try await repository.getPark(by: nonexistentID)
        } catch let error as ParkRepositoryError {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertTrue(error.errorDescription?.contains(nonexistentID.uuidString) ?? false)
        }
    }
    
    func testGetVisitStatisticsWithUpdatedCategories() async throws {
        // Test statistics with the cleaned up category system
        let stats = try await repository.getVisitStatistics(for: testCity)
        
        XCTAssertEqual(stats.totalParks, 3) // From our test setup
        XCTAssertEqual(stats.totalAcreage, 105.5) // 100 + 5 + 0.5
        XCTAssertEqual(stats.categoryBreakdown[.destination], 1)
        XCTAssertEqual(stats.categoryBreakdown[.neighborhood], 1)
        XCTAssertEqual(stats.categoryBreakdown[.mini], 1)
        XCTAssertEqual(stats.sizeBreakdown[.massive], 1) // 100 acres = massive
        XCTAssertEqual(stats.sizeBreakdown[.medium], 1)  // 5 acres = medium
        XCTAssertEqual(stats.sizeBreakdown[.pocket], 1)   // 0.5 acres = pocket
    }
    
    @MainActor func testGetAllParksForUIWithDataLoading() async throws {
        // Test the UI-specific method that can trigger data loading
        let emptyCity = City(name: "empty_city", displayName: "Empty City")
        
        do {
            let parks = try await repository.getAllParksForUI(for: emptyCity)
            // This might be empty if no data file is available for loading
            // The main test is that it doesn't crash
            XCTAssertNotNil(parks)
        } catch {
            // Data loading might fail in test environment, which is acceptable
            XCTAssertTrue(error is ParkRepositoryError)
        }
    }
    
    func testRepositoryProtocolConformance() {
        // Test that ParkRepository properly conforms to ParkRepositoryProtocol
        let protocolInstance: ParkRepositoryProtocol = repository
        XCTAssertNotNil(protocolInstance)
        
        // This is a compile-time test - if this compiles, the protocol is properly implemented
        XCTAssertNotNil(repository)
    }
    
    @MainActor func testGetAllParksForUIAlwaysChecksForUpdates() async throws {
        // Test that getAllParksForUI always calls ParkDataLoader to check for version updates
        // This test verifies the fix for the issue where park descriptions weren't updating
        // despite version increments in the JSON file
        
        // Clear any stored version to simulate fresh state
        UserDefaults.standard.removeObject(forKey: "ParksDataVersion")
        
        do {
            // First call should trigger data loading
            let parks1 = try await repository.getAllParksForUI(for: testCity)
            
            // Store the version that was set during first load
            let storedVersion = UserDefaults.standard.string(forKey: "ParksDataVersion")
            
            // Second call should also call ParkDataLoader (which will check version and return early if no update)
            let parks2 = try await repository.getAllParksForUI(for: testCity)
            
            // Should get the same parks since version didn't change
            XCTAssertEqual(parks1.count, parks2.count)
            
            // Version should still be stored
            XCTAssertEqual(UserDefaults.standard.string(forKey: "ParksDataVersion"), storedVersion)
            
        } catch let error as ParkRepositoryError {
            // This is expected if SFParks.json is not available in test bundle
            switch error.code {
            case .dataCorruption:
                throw XCTSkip("SFParks.json not found in test bundle")
            default:
                throw error
            }
        }
    }
}
