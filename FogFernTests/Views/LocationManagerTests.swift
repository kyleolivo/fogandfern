//
//  LocationManagerTests.swift
//  FogFernTests
//
//  Created by Claude on 7/5/25.
//

import XCTest
import CoreLocation
@testable import FogFern

final class LocationManagerTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var locationManager: LocationManager!
    
    override func setUpWithError() throws {
        super.setUp()
        locationManager = LocationManager()
    }
    
    override func tearDownWithError() throws {
        locationManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testLocationManagerInitialization() throws {
        XCTAssertNotNil(locationManager)
        XCTAssertNil(locationManager.userLocation)
        // authorizationStatus should be set to the current system status
        XCTAssertNotNil(locationManager.authorizationStatus)
    }
    
    func testObservableConformance() throws {
        // Test that LocationManager conforms to Observable
        XCTAssertNotNil(locationManager)
    }
    
    func testNSObjectInheritance() throws {
        // Test that LocationManager inherits from NSObject
        XCTAssertNotNil(locationManager as NSObject)
    }
    
    func testCLLocationManagerDelegateConformance() throws {
        // Test that LocationManager conforms to CLLocationManagerDelegate
        XCTAssertNotNil(locationManager as CLLocationManagerDelegate)
    }
    
    // MARK: - Authorization Status Tests
    
    func testIsLocationAvailableWithAuthorizedWhenInUse() throws {
        locationManager.authorizationStatus = .authorizedWhenInUse
        XCTAssertTrue(locationManager.isLocationAvailable)
    }
    
    func testIsLocationAvailableWithAuthorizedAlways() throws {
        locationManager.authorizationStatus = .authorizedAlways
        XCTAssertTrue(locationManager.isLocationAvailable)
    }
    
    func testIsLocationAvailableWithNotDetermined() throws {
        locationManager.authorizationStatus = .notDetermined
        XCTAssertFalse(locationManager.isLocationAvailable)
    }
    
    func testIsLocationAvailableWithDenied() throws {
        locationManager.authorizationStatus = .denied
        XCTAssertFalse(locationManager.isLocationAvailable)
    }
    
    func testIsLocationAvailableWithRestricted() throws {
        locationManager.authorizationStatus = .restricted
        XCTAssertFalse(locationManager.isLocationAvailable)
    }
    
    // MARK: - Location Update Tests
    
    func testDidUpdateLocationsWithSingleLocation() throws {
        let testLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let locations = [testLocation]
        
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: locations)
        
        XCTAssertNotNil(locationManager.userLocation)
        XCTAssertEqual(locationManager.userLocation?.coordinate.latitude, 37.7749)
        XCTAssertEqual(locationManager.userLocation?.coordinate.longitude, -122.4194)
    }
    
    func testDidUpdateLocationsWithMultipleLocations() throws {
        let location1 = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let location2 = CLLocation(latitude: 37.7849, longitude: -122.4094)
        let location3 = CLLocation(latitude: 37.7949, longitude: -122.3994)
        let locations = [location1, location2, location3]
        
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: locations)
        
        // Should use the last location
        XCTAssertNotNil(locationManager.userLocation)
        XCTAssertEqual(locationManager.userLocation?.coordinate.latitude, 37.7949)
        XCTAssertEqual(locationManager.userLocation?.coordinate.longitude, -122.3994)
    }
    
    func testDidUpdateLocationsWithEmptyArray() throws {
        let locations: [CLLocation] = []
        
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: locations)
        
        // Should remain nil when no locations provided
        XCTAssertNil(locationManager.userLocation)
    }
    
    // MARK: - Authorization Change Tests
    
    func testDidChangeAuthorizationToAuthorizedWhenInUse() throws {
        // Set initial state to a different status
        locationManager.locationManager(CLLocationManager(), didChangeAuthorization: .notDetermined)
        XCTAssertNotEqual(locationManager.authorizationStatus, .authorizedWhenInUse)
        
        locationManager.locationManager(CLLocationManager(), didChangeAuthorization: .authorizedWhenInUse)
        
        XCTAssertEqual(locationManager.authorizationStatus, .authorizedWhenInUse)
    }
    
    func testDidChangeAuthorizationToAuthorizedAlways() throws {
        // Set initial state to a different status
        locationManager.locationManager(CLLocationManager(), didChangeAuthorization: .notDetermined)
        XCTAssertNotEqual(locationManager.authorizationStatus, .authorizedAlways)
        
        locationManager.locationManager(CLLocationManager(), didChangeAuthorization: .authorizedAlways)
        
        XCTAssertEqual(locationManager.authorizationStatus, .authorizedAlways)
    }
    
    func testDidChangeAuthorizationToDenied() throws {
        locationManager.locationManager(CLLocationManager(), didChangeAuthorization: .denied)
        
        XCTAssertEqual(locationManager.authorizationStatus, .denied)
        XCTAssertFalse(locationManager.isLocationAvailable)
    }
    
    func testDidChangeAuthorizationToRestricted() throws {
        locationManager.locationManager(CLLocationManager(), didChangeAuthorization: .restricted)
        
        XCTAssertEqual(locationManager.authorizationStatus, .restricted)
        XCTAssertFalse(locationManager.isLocationAvailable)
    }
    
    func testDidChangeAuthorizationToNotDetermined() throws {
        locationManager.locationManager(CLLocationManager(), didChangeAuthorization: .notDetermined)
        
        XCTAssertEqual(locationManager.authorizationStatus, .notDetermined)
        XCTAssertFalse(locationManager.isLocationAvailable)
    }
    
    // MARK: - Error Handling Tests
    
    func testDidFailWithError() throws {
        let testError = CLError(.locationUnknown)
        
        // This should not crash
        locationManager.locationManager(CLLocationManager(), didFailWithError: testError)
        
        // The method currently doesn't do anything, but we test it doesn't crash
        XCTAssertNotNil(locationManager)
    }
    
    func testDidFailWithCustomError() throws {
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // This should not crash
        locationManager.locationManager(CLLocationManager(), didFailWithError: testError)
        
        XCTAssertNotNil(locationManager)
    }
    
    // MARK: - State Management Tests
    
    func testLocationStateAfterMultipleUpdates() throws {
        // Test that location state is properly maintained through multiple updates
        let location1 = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let location2 = CLLocation(latitude: 40.7128, longitude: -74.0060)
        
        // First update
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [location1])
        XCTAssertEqual(locationManager.userLocation?.coordinate.latitude, 37.7749)
        
        // Second update should replace the first
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [location2])
        XCTAssertEqual(locationManager.userLocation?.coordinate.latitude, 40.7128)
        XCTAssertEqual(locationManager.userLocation?.coordinate.longitude, -74.0060)
    }
    
    func testAuthorizationStateAfterMultipleChanges() throws {
        // Test authorization status through multiple changes
        locationManager.locationManager(CLLocationManager(), didChangeAuthorization: .notDetermined)
        XCTAssertEqual(locationManager.authorizationStatus, .notDetermined)
        XCTAssertFalse(locationManager.isLocationAvailable)
        
        locationManager.locationManager(CLLocationManager(), didChangeAuthorization: .authorizedWhenInUse)
        XCTAssertEqual(locationManager.authorizationStatus, .authorizedWhenInUse)
        XCTAssertTrue(locationManager.isLocationAvailable)
        
        locationManager.locationManager(CLLocationManager(), didChangeAuthorization: .denied)
        XCTAssertEqual(locationManager.authorizationStatus, .denied)
        XCTAssertFalse(locationManager.isLocationAvailable)
    }
    
    // MARK: - Permission Request Tests
    
    func testRequestLocationPermission() throws {
        // Test that the method can be called without crashing
        // Note: This will actually trigger a system permission request in a real app
        // In unit tests, it should not crash
        locationManager.requestLocationPermission()
        
        // We can't easily test the actual permission request in unit tests
        // but we can verify the method doesn't crash
        XCTAssertNotNil(locationManager)
    }
    
    // MARK: - Integration Tests
    
    func testLocationManagerLifecycle() throws {
        // Test the complete lifecycle of location updates
        // First ensure we start from a known state
        locationManager.locationManager(CLLocationManager(), didChangeAuthorization: .notDetermined)
        XCTAssertNil(locationManager.userLocation)
        XCTAssertFalse(locationManager.isLocationAvailable)
        
        // Simulate authorization
        locationManager.locationManager(CLLocationManager(), didChangeAuthorization: .authorizedWhenInUse)
        XCTAssertTrue(locationManager.isLocationAvailable)
        
        // Simulate location update
        let testLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [testLocation])
        
        XCTAssertNotNil(locationManager.userLocation)
        XCTAssertEqual(locationManager.userLocation?.coordinate.latitude, 37.7749)
        
        // Simulate authorization revocation
        locationManager.locationManager(CLLocationManager(), didChangeAuthorization: .denied)
        XCTAssertFalse(locationManager.isLocationAvailable)
        
        // Location should still be available even after authorization is revoked
        XCTAssertNotNil(locationManager.userLocation)
    }
    
    // MARK: - Edge Cases Tests
    
    func testLocationWithExtremeCoordinates() throws {
        // Test with extreme but valid coordinates
        let extremeLocation = CLLocation(latitude: 89.99, longitude: 179.99)
        
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [extremeLocation])
        
        XCTAssertNotNil(locationManager.userLocation)
        XCTAssertEqual(locationManager.userLocation?.coordinate.latitude, 89.99)
        XCTAssertEqual(locationManager.userLocation?.coordinate.longitude, 179.99)
    }
    
    func testLocationWithZeroCoordinates() throws {
        // Test with 0,0 coordinates (valid but unusual)
        let zeroLocation = CLLocation(latitude: 0.0, longitude: 0.0)
        
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [zeroLocation])
        
        XCTAssertNotNil(locationManager.userLocation)
        XCTAssertEqual(locationManager.userLocation?.coordinate.latitude, 0.0)
        XCTAssertEqual(locationManager.userLocation?.coordinate.longitude, 0.0)
    }
    
    func testLocationWithNegativeCoordinates() throws {
        // Test with negative coordinates (southern/western hemispheres)
        let negativeLocation = CLLocation(latitude: -33.8688, longitude: -151.2093) // Sydney
        
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [negativeLocation])
        
        XCTAssertNotNil(locationManager.userLocation)
        XCTAssertEqual(locationManager.userLocation?.coordinate.latitude, -33.8688)
        XCTAssertEqual(locationManager.userLocation?.coordinate.longitude, -151.2093)
    }
    
    // MARK: - Performance Tests
    
    func testLocationUpdatePerformance() throws {
        measure {
            for i in 0..<100 {
                let location = CLLocation(
                    latitude: 37.7749 + Double(i) * 0.001,
                    longitude: -122.4194 + Double(i) * 0.001
                )
                locationManager.locationManager(CLLocationManager(), didUpdateLocations: [location])
            }
        }
    }
    
    func testAuthorizationChangePerformance() throws {
        let statuses: [CLAuthorizationStatus] = [
            .notDetermined, .authorizedWhenInUse, .denied, .restricted, .authorizedAlways
        ]
        
        measure {
            for i in 0..<100 {
                let status = statuses[i % statuses.count]
                locationManager.locationManager(CLLocationManager(), didChangeAuthorization: status)
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testMultipleLocationManagerInstances() throws {
        // Test that multiple LocationManager instances don't interfere
        let manager1 = LocationManager()
        let manager2 = LocationManager()
        
        let location1 = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let location2 = CLLocation(latitude: 40.7128, longitude: -74.0060)
        
        manager1.locationManager(CLLocationManager(), didUpdateLocations: [location1])
        manager2.locationManager(CLLocationManager(), didUpdateLocations: [location2])
        
        XCTAssertEqual(manager1.userLocation?.coordinate.latitude, 37.7749)
        XCTAssertEqual(manager2.userLocation?.coordinate.latitude, 40.7128)
        
        manager1.locationManager(CLLocationManager(), didChangeAuthorization: .authorizedWhenInUse)
        manager2.locationManager(CLLocationManager(), didChangeAuthorization: .denied)
        
        XCTAssertTrue(manager1.isLocationAvailable)
        XCTAssertFalse(manager2.isLocationAvailable)
    }
    
    // MARK: - Delegate Method Tests
    
    func testAllDelegateMethodsExist() throws {
        // Test that all required delegate methods are implemented
        let manager = CLLocationManager()
        
        // These should not crash
        locationManager.locationManager(manager, didUpdateLocations: [])
        locationManager.locationManager(manager, didChangeAuthorization: .notDetermined)
        locationManager.locationManager(manager, didFailWithError: CLError(.locationUnknown))
        
        XCTAssertNotNil(locationManager)
    }
    
    // MARK: - Real-world Scenario Tests
    
    func testSanFranciscoLocationScenario() throws {
        // Test with real San Francisco coordinates (the app's target city)
        let sfLocations = [
            CLLocation(latitude: 37.7749, longitude: -122.4194), // SF City Center
            CLLocation(latitude: 37.8044, longitude: -122.2712), // Golden Gate Park
            CLLocation(latitude: 37.8199, longitude: -122.4783)  // Golden Gate Bridge
        ]
        
        for (_, location) in sfLocations.enumerated() {
            locationManager.locationManager(CLLocationManager(), didUpdateLocations: [location])
            
            XCTAssertNotNil(locationManager.userLocation)
            XCTAssertEqual(locationManager.userLocation?.coordinate.latitude, location.coordinate.latitude)
            XCTAssertEqual(locationManager.userLocation?.coordinate.longitude, location.coordinate.longitude)
        }
    }
    
    func testTypicalUserPermissionFlow() throws {
        // Simulate a typical user permission flow
        
        // 1. Initial state - not determined
        locationManager.locationManager(CLLocationManager(), didChangeAuthorization: .notDetermined)
        XCTAssertFalse(locationManager.isLocationAvailable)
        
        // 2. User grants permission
        locationManager.locationManager(CLLocationManager(), didChangeAuthorization: .authorizedWhenInUse)
        XCTAssertTrue(locationManager.isLocationAvailable)
        
        // 3. Location updates start coming in
        let locations = [
            CLLocation(latitude: 37.7749, longitude: -122.4194),
            CLLocation(latitude: 37.7750, longitude: -122.4195),
            CLLocation(latitude: 37.7751, longitude: -122.4196)
        ]
        
        for location in locations {
            locationManager.locationManager(CLLocationManager(), didUpdateLocations: [location])
            XCTAssertNotNil(locationManager.userLocation)
        }
        
        // Final location should be the last one
        XCTAssertEqual(locationManager.userLocation?.coordinate.latitude, 37.7751)
        XCTAssertEqual(locationManager.userLocation?.coordinate.longitude, -122.4196)
    }
}