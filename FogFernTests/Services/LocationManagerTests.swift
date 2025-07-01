//
//  LocationManagerTests.swift
//  FogFernTests
//
//  Created by Claude on 6/29/25.
//

import XCTest
import CoreLocation
@testable import FogFern

final class LocationManagerTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var locationManager: LocationManager!
    var mockCLLocationManager: MockCLLocationManager!
    
    override func setUpWithError() throws {
        super.setUp()
        locationManager = LocationManager()
    }
    
    override func tearDownWithError() throws {
        locationManager = nil
        mockCLLocationManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testLocationManagerInitialization() throws {
        XCTAssertNotNil(locationManager)
        XCTAssertNil(locationManager.userLocation)
        
        // Authorization status should be set from CLLocationManager
        // We can't control this in unit tests, but we can verify it's been set
        let validStatuses: [CLAuthorizationStatus] = [
            .notDetermined, .denied, .restricted, .authorizedWhenInUse, .authorizedAlways
        ]
        XCTAssertTrue(validStatuses.contains(locationManager.authorizationStatus))
    }
    
    func testIsLocationAvailableProperty() throws {
        // Test with authorized statuses
        locationManager.authorizationStatus = .authorizedWhenInUse
        XCTAssertTrue(locationManager.isLocationAvailable)
        
        locationManager.authorizationStatus = .authorizedAlways
        XCTAssertTrue(locationManager.isLocationAvailable)
        
        // Test with unauthorized statuses
        locationManager.authorizationStatus = .notDetermined
        XCTAssertFalse(locationManager.isLocationAvailable)
        
        locationManager.authorizationStatus = .denied
        XCTAssertFalse(locationManager.isLocationAvailable)
        
        locationManager.authorizationStatus = .restricted
        XCTAssertFalse(locationManager.isLocationAvailable)
    }
    
    // MARK: - Permission Request Tests
    
    func testRequestLocationPermission() throws {
        // This test verifies the method can be called without crashing
        // We can't easily test the actual permission request in unit tests
        XCTAssertNoThrow(locationManager.requestLocationPermission())
    }
    
    // MARK: - Delegate Method Tests
    
    func testDidUpdateLocationsDelegate() throws {
        let testLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let locations = [testLocation]
        
        // Simulate delegate callback
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: locations)
        
        XCTAssertNotNil(locationManager.userLocation)
        XCTAssertEqual(locationManager.userLocation?.coordinate.latitude ?? 0, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(locationManager.userLocation?.coordinate.longitude ?? 0, -122.4194, accuracy: 0.0001)
    }
    
    func testDidUpdateLocationsWithMultipleLocations() throws {
        let location1 = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let location2 = CLLocation(latitude: 37.7849, longitude: -122.4294)
        let location3 = CLLocation(latitude: 37.7949, longitude: -122.4394)
        let locations = [location1, location2, location3]
        
        // Should use the last location
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: locations)
        
        XCTAssertNotNil(locationManager.userLocation)
        XCTAssertEqual(locationManager.userLocation?.coordinate.latitude ?? 0, 37.7949, accuracy: 0.0001)
        XCTAssertEqual(locationManager.userLocation?.coordinate.longitude ?? 0, -122.4394, accuracy: 0.0001)
    }
    
    func testDidUpdateLocationsWithEmptyArray() throws {
        let locations: [CLLocation] = []
        
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: locations)
        
        // Should remain nil with empty array
        XCTAssertNil(locationManager.userLocation)
    }
    
    func testDidChangeAuthorizationToAuthorizedWhenInUse() throws {
        locationManager.locationManager(CLLocationManager(), didChangeAuthorization: .authorizedWhenInUse)
        
        XCTAssertEqual(locationManager.authorizationStatus, .authorizedWhenInUse)
        XCTAssertTrue(locationManager.isLocationAvailable)
    }
    
    func testDidChangeAuthorizationToAuthorizedAlways() throws {
        locationManager.locationManager(CLLocationManager(), didChangeAuthorization: .authorizedAlways)
        
        XCTAssertEqual(locationManager.authorizationStatus, .authorizedAlways)
        XCTAssertTrue(locationManager.isLocationAvailable)
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
    
    func testDidFailWithError() throws {
        let testError = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // This should not crash the app
        XCTAssertNoThrow(locationManager.locationManager(CLLocationManager(), didFailWithError: testError))
    }
    
    // MARK: - Observable Behavior Tests
    
    func testObservablePropertyChanges() throws {
        let initialStatus = locationManager.authorizationStatus
        let initialLocation = locationManager.userLocation
        
        // Test that properties can be modified (Observable should allow this)
        // Choose a different status based on what the initial status is
        let newStatus: CLAuthorizationStatus = (initialStatus == .authorizedWhenInUse) ? .denied : .authorizedWhenInUse
        locationManager.authorizationStatus = newStatus
        XCTAssertNotEqual(locationManager.authorizationStatus, initialStatus)
        
        let newLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        locationManager.userLocation = newLocation
        XCTAssertNotEqual(locationManager.userLocation, initialLocation)
        XCTAssertEqual(locationManager.userLocation?.coordinate.latitude ?? 0, 37.7749, accuracy: 0.0001)
    }
    
    // MARK: - Location Accuracy Tests
    
    func testLocationAccuracy() throws {
        // Test high precision coordinates
        let preciseLocation = CLLocation(latitude: 37.77492588, longitude: -122.41942199)
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [preciseLocation])
        
        XCTAssertNotNil(locationManager.userLocation)
        XCTAssertEqual(locationManager.userLocation?.coordinate.latitude ?? 0, 37.77492588, accuracy: 0.00000001)
        XCTAssertEqual(locationManager.userLocation?.coordinate.longitude ?? 0, -122.41942199, accuracy: 0.00000001)
    }
    
    func testLocationWithAltitude() throws {
        let locationWithAltitude = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 100.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 10.0,
            timestamp: Date()
        )
        
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [locationWithAltitude])
        
        XCTAssertNotNil(locationManager.userLocation)
        XCTAssertEqual(locationManager.userLocation?.altitude ?? 0, 100.0, accuracy: 0.1)
        XCTAssertEqual(locationManager.userLocation?.horizontalAccuracy ?? 0, 5.0, accuracy: 0.1)
        XCTAssertEqual(locationManager.userLocation?.verticalAccuracy ?? 0, 10.0, accuracy: 0.1)
    }
    
    // MARK: - Edge Cases Tests
    
    func testExtremeCoordinates() throws {
        // Test with extreme but valid coordinates
        let extremeLocation = CLLocation(latitude: 89.999, longitude: 179.999)
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [extremeLocation])
        
        XCTAssertNotNil(locationManager.userLocation)
        XCTAssertEqual(locationManager.userLocation?.coordinate.latitude ?? 0, 89.999, accuracy: 0.001)
        XCTAssertEqual(locationManager.userLocation?.coordinate.longitude ?? 0, 179.999, accuracy: 0.001)
    }
    
    func testInvalidCoordinates() throws {
        // CLLocation should handle invalid coordinates, but let's test edge cases
        let invalidLocation = CLLocation(latitude: 91.0, longitude: 181.0) // Out of range
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [invalidLocation])
        
        // CLLocation might clamp or handle these values differently
        XCTAssertNotNil(locationManager.userLocation)
    }
    
    func testVeryOldLocation() throws {
        let oldDate = Date(timeIntervalSince1970: 0) // January 1, 1970
        let oldLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: -1.0,
            timestamp: oldDate
        )
        
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [oldLocation])
        
        XCTAssertNotNil(locationManager.userLocation)
        XCTAssertEqual(locationManager.userLocation?.timestamp, oldDate)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentLocationUpdates() throws {
        let expectation = XCTestExpectation(description: "Concurrent location updates")
        expectation.expectedFulfillmentCount = 10
        
        // Test concurrent access to location updates
        for i in 0..<10 {
            DispatchQueue.global().async {
                let location = CLLocation(
                    latitude: 37.7749 + Double(i) * 0.001,
                    longitude: -122.4194 + Double(i) * 0.001
                )
                
                self.locationManager.locationManager(CLLocationManager(), didUpdateLocations: [location])
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Should have some location set (last one wins)
        XCTAssertNotNil(locationManager.userLocation)
    }
    
    func testConcurrentAuthorizationChanges() throws {
        let expectation = XCTestExpectation(description: "Concurrent authorization changes")
        expectation.expectedFulfillmentCount = 5
        
        let statuses: [CLAuthorizationStatus] = [
            .notDetermined, .denied, .restricted, .authorizedWhenInUse, .authorizedAlways
        ]
        
        for status in statuses {
            DispatchQueue.global().async {
                self.locationManager.locationManager(CLLocationManager(), didChangeAuthorization: status)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Should have one of the valid statuses
        XCTAssertTrue(statuses.contains(locationManager.authorizationStatus))
    }
    
    // MARK: - Performance Tests
    
    func testLocationUpdatePerformance() throws {
        let locations = (0..<1000).map { i in
            CLLocation(
                latitude: 37.7749 + Double(i) * 0.0001,
                longitude: -122.4194 + Double(i) * 0.0001
            )
        }
        
        measure {
            for location in locations {
                locationManager.locationManager(CLLocationManager(), didUpdateLocations: [location])
            }
        }
    }
    
    func testAuthorizationChangePerformance() throws {
        let statuses: [CLAuthorizationStatus] = [
            .notDetermined, .denied, .restricted, .authorizedWhenInUse, .authorizedAlways
        ]
        
        measure {
            for _ in 0..<1000 {
                for status in statuses {
                    locationManager.locationManager(CLLocationManager(), didChangeAuthorization: status)
                }
            }
        }
    }
    
    func testIsLocationAvailablePerformance() throws {
        measure {
            for _ in 0..<10000 {
                let _ = locationManager.isLocationAvailable
            }
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testLocationManagerRetainCycle() throws {
        weak var weakLocationManager: LocationManager?
        
        autoreleasepool {
            let tempLocationManager = LocationManager()
            weakLocationManager = tempLocationManager
            
            // Use the location manager
            tempLocationManager.requestLocationPermission()
            
            // Add some location data
            let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
            tempLocationManager.locationManager(CLLocationManager(), didUpdateLocations: [location])
        }
        
        // Should be deallocated (no retain cycle)
        XCTAssertNil(weakLocationManager)
    }
    
    // MARK: - Integration Tests
    
    func testLocationManagerInRealWorldScenario() throws {
        // Simulate a real-world usage pattern
        
        // 1. Request permission
        locationManager.requestLocationPermission()
        
        // 2. Authorization changes to authorized
        locationManager.locationManager(CLLocationManager(), didChangeAuthorization: .authorizedWhenInUse)
        XCTAssertTrue(locationManager.isLocationAvailable)
        
        // 3. Receive location updates
        let sanFranciscoLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [sanFranciscoLocation])
        
        // 4. Verify location is set
        XCTAssertNotNil(locationManager.userLocation)
        XCTAssertEqual(locationManager.userLocation?.coordinate.latitude ?? 0, 37.7749, accuracy: 0.0001)
        
        // 5. Move to a new location
        let newLocation = CLLocation(latitude: 37.7849, longitude: -122.4294)
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [newLocation])
        
        // 6. Verify location updated
        XCTAssertEqual(locationManager.userLocation?.coordinate.latitude ?? 0, 37.7849, accuracy: 0.0001)
        XCTAssertEqual(locationManager.userLocation?.coordinate.longitude ?? 0, -122.4294, accuracy: 0.0001)
        
        // 7. Authorization denied
        locationManager.locationManager(CLLocationManager(), didChangeAuthorization: .denied)
        XCTAssertFalse(locationManager.isLocationAvailable)
        XCTAssertEqual(locationManager.authorizationStatus, .denied)
    }
}

// MARK: - Mock Objects

class MockCLLocationManager {
    var delegate: CLLocationManagerDelegate?
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    func requestWhenInUseAuthorization() {
        // Mock implementation
    }
    
    func startUpdatingLocation() {
        // Mock implementation
    }
    
    func stopUpdatingLocation() {
        // Mock implementation
    }
}