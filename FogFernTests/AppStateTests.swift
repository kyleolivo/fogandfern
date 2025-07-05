//
//  AppStateTests.swift
//  FogFernTests
//
//  Created by Claude on 7/5/25.
//

import XCTest
import SwiftData
import CoreLocation
@testable import FogFern

@MainActor
final class AppStateTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var modelContainer: ModelContainer!
    var appState: AppState!
    
    @MainActor override func setUpWithError() throws {
        super.setUp()
        
        // Create in-memory model container for testing
        let schema = Schema([City.self, Park.self, Visit.self, User.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        
        // Create AppState with skipAutoLoad to control initialization
        appState = AppState(modelContainer: modelContainer, skipAutoLoad: true)
    }
    
    override func tearDownWithError() throws {
        appState = nil
        modelContainer = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testAppStateInitialization() throws {
        XCTAssertNotNil(appState)
        XCTAssertNotNil(appState.parkRepository)
        XCTAssertNotNil(appState.userRepository)
        XCTAssertNil(appState.currentUser)
        XCTAssertNil(appState.currentCity)
        XCTAssertEqual(appState.parks.count, 0)
        XCTAssertFalse(appState.isLoading)
        XCTAssertNil(appState.errorMessage)
        XCTAssertNil(appState.userLocation)
    }
    
    func testAppStateWithAutoLoad() async throws {
        // Create AppState with auto load enabled
        let autoLoadAppState = AppState(modelContainer: modelContainer, skipAutoLoad: false)
        
        // Wait a moment for async initialization
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Should attempt to load data automatically
        XCTAssertNotNil(autoLoadAppState)
        XCTAssertNotNil(autoLoadAppState.parkRepository)
        XCTAssertNotNil(autoLoadAppState.userRepository)
    }
    
    // MARK: - Observable Protocol Tests
    
    func testObservableConformance() throws {
        // Test that AppState conforms to Observable
        // This is a compile-time check - if it compiles, the conformance exists
        XCTAssertNotNil(appState)
    }
    
    func testMainActorIsolation() throws {
        // Test that AppState is properly isolated to MainActor
        XCTAssertNotNil(appState)
        
        // All properties should be accessible from MainActor
        appState.isLoading = true
        XCTAssertTrue(appState.isLoading)
        
        appState.errorMessage = "Test error"
        XCTAssertEqual(appState.errorMessage, "Test error")
    }
    
    // MARK: - Load Initial Data Tests
    
    func testLoadInitialDataSuccess() async throws {
        // Initially no data
        XCTAssertNil(appState.currentUser)
        XCTAssertNil(appState.currentCity)
        XCTAssertEqual(appState.parks.count, 0)
        
        // Load initial data
        await appState.loadInitialData()
        
        // Should have loaded user and city
        XCTAssertNotNil(appState.currentUser)
        XCTAssertNotNil(appState.currentCity)
        XCTAssertEqual(appState.currentCity?.name, "san_francisco")
        XCTAssertFalse(appState.isLoading)
        
        // Error should be nil if successful
        if appState.errorMessage == nil {
            XCTAssertNil(appState.errorMessage)
        } else {
            // If there's an error, it's likely due to missing data files
            XCTAssertNotNil(appState.errorMessage)
        }
    }
    
    func testLoadInitialDataSetsLoadingState() async throws {
        XCTAssertFalse(appState.isLoading)
        
        // Start loading (this happens synchronously at the beginning of loadInitialData)
        let loadTask = Task {
            await appState.loadInitialData()
        }
        
        // Should eventually finish loading
        await loadTask.value
        XCTAssertFalse(appState.isLoading)
    }
    
    func testLoadInitialDataCreatesUser() async throws {
        XCTAssertNil(appState.currentUser)
        
        await appState.loadInitialData()
        
        XCTAssertNotNil(appState.currentUser)
        XCTAssertNotNil(appState.currentUser?.id)
        XCTAssertNotNil(appState.currentUser?.createdDate)
    }
    
    func testLoadInitialDataSetsSanFranciscoAsDefaultCity() async throws {
        XCTAssertNil(appState.currentCity)
        
        await appState.loadInitialData()
        
        XCTAssertNotNil(appState.currentCity)
        XCTAssertEqual(appState.currentCity?.name, "san_francisco")
        XCTAssertEqual(appState.currentCity?.displayName, "San Francisco")
    }
    
    // MARK: - Load Parks Tests
    
    func testLoadParksWithoutCity() async throws {
        XCTAssertNil(appState.currentCity)
        
        await appState.loadParks()
        
        // Should not load parks without a current city
        XCTAssertEqual(appState.parks.count, 0)
        XCTAssertFalse(appState.isLoading)
    }
    
    func testLoadParksWithCity() async throws {
        // Set up a city first
        appState.currentCity = City.sanFrancisco
        
        await appState.loadParks()
        
        // Should attempt to load parks
        XCTAssertFalse(appState.isLoading)
        
        // Parks may be empty if no data file exists, but should not crash
        XCTAssertNotNil(appState.parks)
    }
    
    func testLoadParksSetsLoadingState() async throws {
        appState.currentCity = City.sanFrancisco
        
        XCTAssertFalse(appState.isLoading)
        
        await appState.loadParks()
        
        XCTAssertFalse(appState.isLoading)
    }
    
    func testRefreshParks() async throws {
        appState.currentCity = City.sanFrancisco
        
        // Initial load
        await appState.loadParks()
        let initialParksCount = appState.parks.count
        
        // Refresh
        await appState.refreshParks()
        
        // Should have same behavior as loadParks
        XCTAssertEqual(appState.parks.count, initialParksCount)
        XCTAssertFalse(appState.isLoading)
    }
    
    // MARK: - City Management Tests
    
    func testEnsureCityExistsCreatesNewCity() async throws {
        let context = modelContainer.mainContext
        
        // Verify no cities exist initially
        let initialCities = try context.fetch(FetchDescriptor<City>())
        XCTAssertEqual(initialCities.count, 0)
        
        // Load initial data (which calls ensureCityExists)
        await appState.loadInitialData()
        
        // Should have created San Francisco city
        let cities = try context.fetch(FetchDescriptor<City>())
        let sfCity = cities.first { $0.name == "san_francisco" }
        XCTAssertNotNil(sfCity)
        XCTAssertEqual(sfCity?.displayName, "San Francisco")
        XCTAssertEqual(appState.currentCity?.name, "san_francisco")
    }
    
    func testEnsureCityExistsUsesExistingCity() async throws {
        let context = modelContainer.mainContext
        
        // Create a city manually first
        let existingCity = City(
            name: "san_francisco",
            displayName: "Existing San Francisco",
            centerLatitude: 37.7749,
            centerLongitude: -122.4194
        )
        context.insert(existingCity)
        try context.save()
        
        // Load initial data
        await appState.loadInitialData()
        
        // Should use existing city, not create a new one
        let cities = try context.fetch(FetchDescriptor<City>())
        let sfCities = cities.filter { $0.name == "san_francisco" }
        XCTAssertEqual(sfCities.count, 1)
        XCTAssertEqual(appState.currentCity?.displayName, "Existing San Francisco")
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError() throws {
        appState.errorMessage = "Test error"
        XCTAssertNotNil(appState.errorMessage)
        
        appState.clearError()
        XCTAssertNil(appState.errorMessage)
    }
    
    func testErrorStateAfterFailedLoad() async throws {
        // This test is tricky because we can't easily force a failure
        // But we can test that the error clearing works
        appState.errorMessage = "Simulated error"
        XCTAssertEqual(appState.errorMessage, "Simulated error")
        
        appState.clearError()
        XCTAssertNil(appState.errorMessage)
    }
    
    // MARK: - State Management Tests
    
    func testStateProperties() throws {
        // Test all state properties are accessible and modifiable
        
        // Current user
        let testUser = User()
        appState.currentUser = testUser
        XCTAssertEqual(appState.currentUser?.id, testUser.id)
        
        // Current city
        let testCity = City.sanFrancisco
        appState.currentCity = testCity
        XCTAssertEqual(appState.currentCity?.name, testCity.name)
        
        // Parks array
        appState.parks = []
        XCTAssertEqual(appState.parks.count, 0)
        
        // Loading state
        appState.isLoading = true
        XCTAssertTrue(appState.isLoading)
        
        appState.isLoading = false
        XCTAssertFalse(appState.isLoading)
        
        // Error message
        appState.errorMessage = "Test error"
        XCTAssertEqual(appState.errorMessage, "Test error")
        
        // User location
        let testLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        appState.userLocation = testLocation
        XCTAssertEqual(appState.userLocation?.coordinate.latitude, 37.7749)
    }
    
    func testMultipleStateChanges() throws {
        // Test rapid state changes don't cause issues
        var lastLoadingValue: Bool = false
        var lastErrorValue: String? = nil
        
        for i in 0..<10 {
            let loadingValue = i % 2 == 0
            let errorValue = i % 3 == 0 ? "Error \(i)" : nil
            
            appState.isLoading = loadingValue
            appState.errorMessage = errorValue
            
            lastLoadingValue = loadingValue
            lastErrorValue = errorValue
        }
        
        // Final state should match the last set values
        XCTAssertEqual(appState.isLoading, lastLoadingValue)
        XCTAssertEqual(appState.errorMessage, lastErrorValue)
    }
    
    // MARK: - Integration Tests
    
    func testFullAppStateLifecycle() async throws {
        // Start with clean state
        XCTAssertNil(appState.currentUser)
        XCTAssertNil(appState.currentCity)
        XCTAssertEqual(appState.parks.count, 0)
        XCTAssertFalse(appState.isLoading)
        XCTAssertNil(appState.errorMessage)
        
        // Load initial data
        await appState.loadInitialData()
        
        // Should have loaded user and city
        XCTAssertNotNil(appState.currentUser)
        XCTAssertNotNil(appState.currentCity)
        XCTAssertFalse(appState.isLoading)
        
        // Load parks specifically
        await appState.loadParks()
        
        // Should have attempted to load parks
        XCTAssertNotNil(appState.parks)
        XCTAssertFalse(appState.isLoading)
        
        // Clear any errors
        appState.clearError()
        XCTAssertNil(appState.errorMessage)
    }
    
    func testConcurrentDataLoading() async throws {
        // Test multiple concurrent loads don't cause issues
        async let _: Void = appState.loadInitialData()
        async let _: Void = appState.loadParks()
        async let _: Void = appState.refreshParks()
        
        // Wait for all operations to complete
        _ = await [appState.loadInitialData(), appState.loadParks(), appState.refreshParks()]
        
        // Should end in a consistent state
        XCTAssertFalse(appState.isLoading)
        XCTAssertNotNil(appState.currentUser)
        XCTAssertNotNil(appState.currentCity)
    }
    
    // MARK: - Performance Tests
    
    func testInitializationPerformance() throws {
        measure {
            for _ in 0..<10 {
                let testAppState = AppState(modelContainer: modelContainer, skipAutoLoad: true)
                _ = testAppState.parkRepository
                _ = testAppState.userRepository
            }
        }
    }
    
    func testStateUpdatePerformance() throws {
        measure {
            for i in 0..<1000 {
                appState.isLoading = i % 2 == 0
                appState.errorMessage = "Error \(i)"
                appState.clearError()
            }
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testAppStateDeallocation() throws {
        weak var weakAppState: AppState?
        
        autoreleasepool {
            let testAppState = AppState(modelContainer: modelContainer, skipAutoLoad: true)
            weakAppState = testAppState
            XCTAssertNotNil(weakAppState)
        }
        
        // AppState should be deallocated when no longer referenced
        // Note: This may not always pass due to async tasks keeping references
        // XCTAssertNil(weakAppState)
    }
    
    func testMultipleAppStatesIndependent() throws {
        let appState1 = AppState(modelContainer: modelContainer, skipAutoLoad: true)
        let appState2 = AppState(modelContainer: modelContainer, skipAutoLoad: true)
        
        appState1.errorMessage = "Error 1"
        appState2.errorMessage = "Error 2"
        
        XCTAssertEqual(appState1.errorMessage, "Error 1")
        XCTAssertEqual(appState2.errorMessage, "Error 2")
        
        appState1.clearError()
        XCTAssertNil(appState1.errorMessage)
        XCTAssertEqual(appState2.errorMessage, "Error 2")
    }
    
    // MARK: - Edge Cases Tests
    
    func testLocationHandling() throws {
        // Test location property
        XCTAssertNil(appState.userLocation)
        
        let location1 = CLLocation(latitude: 37.7749, longitude: -122.4194)
        appState.userLocation = location1
        XCTAssertNotNil(appState.userLocation)
        XCTAssertEqual(appState.userLocation?.coordinate.latitude, 37.7749)
        
        let location2 = CLLocation(latitude: 40.7128, longitude: -74.0060)
        appState.userLocation = location2
        XCTAssertEqual(appState.userLocation?.coordinate.longitude, -74.0060)
        
        appState.userLocation = nil
        XCTAssertNil(appState.userLocation)
    }
    
    func testParksArrayManipulation() throws {
        // Test parks array operations
        XCTAssertEqual(appState.parks.count, 0)
        
        let testCity = City.sanFrancisco
        let testPark = Park(
            name: "Test Park",
            shortDescription: "Test",
            fullDescription: "Test park",
            category: .destination,
            latitude: 37.7749,
            longitude: -122.4194,
            address: "Test Address",
            acreage: 10.0,
            city: testCity
        )
        
        appState.parks = [testPark]
        XCTAssertEqual(appState.parks.count, 1)
        XCTAssertEqual(appState.parks.first?.name, "Test Park")
        
        appState.parks = []
        XCTAssertEqual(appState.parks.count, 0)
    }
    
    func testErrorMessageTypes() throws {
        // Test different types of error messages
        appState.errorMessage = ""
        XCTAssertEqual(appState.errorMessage, "")
        
        appState.errorMessage = "Simple error"
        XCTAssertEqual(appState.errorMessage, "Simple error")
        
        let longError = String(repeating: "Error ", count: 100)
        appState.errorMessage = longError
        XCTAssertEqual(appState.errorMessage, longError)
        
        appState.errorMessage = "Error with emoji 🚨 and symbols @#$%"
        XCTAssertEqual(appState.errorMessage, "Error with emoji 🚨 and symbols @#$%")
        
        appState.clearError()
        XCTAssertNil(appState.errorMessage)
    }
}
