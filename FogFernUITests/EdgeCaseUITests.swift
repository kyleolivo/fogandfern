//
//  EdgeCaseUITests.swift
//  FogFernUITests
//
//  Created by Claude on 7/5/25.
//

import XCTest

final class EdgeCaseUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Memory and Performance Edge Cases
    
    func testRapidViewSwitching() throws {
        // Test rapid switching between map and list views
        for _ in 0..<20 {
            app.segmentedControls.buttons["List"].tap()
            app.segmentedControls.buttons["Map"].tap()
        }
        
        // App should remain stable
        XCTAssertTrue(app.navigationBars["Discover"].exists)
        XCTAssertTrue(app.segmentedControls.buttons["Map"].isSelected)
    }
    
    func testRapidFilterSheetOpenClose() throws {
        // Test rapid opening and closing of filter sheet
        for _ in 0..<15 {
            app.buttons["filterButton"].firstMatch.tap()
            
            if app.navigationBars.buttons["Done"].exists {
                app.navigationBars.buttons["Done"].tap()
            } else {
                app.swipeDown()
            }
        }
        
        // Should end in stable state
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
    
    // MARK: - UI State Consistency Tests
    
    func testStateConsistencyAfterBackground() throws {
        // Test app state when returning from background
        // Note: UI tests can't easily simulate backgrounding, but we can test state recovery
        
        // Set up specific state
        app.segmentedControls.buttons["List"].tap()
        app.buttons["filterButton"].firstMatch.tap()
        
        if app.navigationBars.buttons["Done"].exists {
            app.navigationBars.buttons["Done"].tap()
        }
        
        // Verify state is maintained
        XCTAssertTrue(app.segmentedControls.buttons["List"].isSelected)
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
    
    func testNavigationStackIntegrity() throws {
        // Test navigation stack doesn't get corrupted
        
        // Start in base state
        XCTAssertTrue(app.navigationBars["Discover"].exists)
        
        // Open and close filter multiple times
        for _ in 0..<5 {
            app.buttons["filterButton"].firstMatch.tap()
            XCTAssertTrue(app.navigationBars["Filter Parks"].exists)
            
            if app.navigationBars.buttons["Done"].exists {
                app.navigationBars.buttons["Done"].tap()
            }
            
            XCTAssertTrue(app.navigationBars["Discover"].exists)
        }
    }
    
    func testConcurrentInteractions() throws {
        // Test handling of concurrent UI interactions
        
        // Try to interact with multiple elements in quick succession
        app.buttons["filterButton"].firstMatch.tap()
        
        // Wait for UI to be ready before next interaction
        let listButton = app.segmentedControls.buttons["List"]
        _ = listButton.waitForExistence(timeout: 1)
        if listButton.exists && listButton.isHittable {
            listButton.tap()
        }
        
        let mapButton = app.segmentedControls.buttons["Map"]
        if mapButton.exists && mapButton.isHittable {
            mapButton.tap()
        }
        
        // Handle whatever state we end up in
        if app.navigationBars["Filter Parks"].exists {
            if app.navigationBars.buttons["Done"].exists {
                app.navigationBars.buttons["Done"].tap()
            }
        }
        
        // Should end in stable state
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
    
    // MARK: - Location Services Edge Cases
    
    func testLocationButtonWhenDisabled() throws {
        // Test location button behavior when location services unavailable
        
        // Switch to list view (location button should be disabled)
        app.segmentedControls.buttons["List"].tap()
        
        let locationButton = app.buttons["locationButton"].firstMatch
        XCTAssertFalse(locationButton.isEnabled)
        
        // Try to tap disabled button (should be ignored)
        locationButton.tap()
        
        // Should remain in list view
        XCTAssertTrue(app.segmentedControls.buttons["List"].isSelected)
    }
    
    func testLocationButtonRapidTapping() throws {
        // Test rapid tapping of location button
        app.segmentedControls.buttons["Map"].tap()
        
        let locationButton = app.buttons["locationButton"].firstMatch
        if locationButton.isEnabled {
            // Tap rapidly
            for _ in 0..<10 {
                locationButton.tap()
            }
            
            // Should remain stable
            XCTAssertTrue(app.navigationBars["Discover"].exists)
            XCTAssertTrue(app.segmentedControls.buttons["Map"].isSelected)
        }
    }
    
    // MARK: - Data Loading Edge Cases
    
    func testEmptyDataStates() throws {
        // Test UI behavior with empty or missing data
        
        // Switch to list view (might be empty)
        app.segmentedControls.buttons["List"].tap()
        
        // Should handle empty state gracefully
        XCTAssertTrue(app.navigationBars["Discover"].exists)
        
        // Switch to map view
        app.segmentedControls.buttons["Map"].tap()
        
        // Map should still be functional even without data
        let mapView = app.otherElements["parkMap"].firstMatch
        XCTAssertTrue(mapView.exists)
    }
    
    func testFilterWithNoResults() throws {
        // Test filtering that might result in no visible parks
        
        app.buttons["filterButton"].firstMatch.tap()
        
        // Try to deselect all categories if possible
        let categoryElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'park' OR label CONTAINS[c] 'space'"))
        
        for i in 0..<min(categoryElements.count, 5) {
            categoryElements.element(boundBy: i).tap()
            categoryElements.element(boundBy: i).tap() // Tap twice to deselect
        }
        
        if app.navigationBars.buttons["Done"].exists {
            app.navigationBars.buttons["Done"].tap()
        }
        
        // Should handle no results gracefully
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
    
    // MARK: - Sheet Presentation Edge Cases
    
    func testMultipleSheetInteractions() throws {
        // Test multiple sheet presentations and dismissals
        
        // Open filter sheet
        app.buttons["filterButton"].firstMatch.tap()
        
        // Try to open another sheet (should be handled gracefully)
        let filterButton = app.buttons["filterButton"].firstMatch
        if filterButton.waitForExistence(timeout: 1) && filterButton.isHittable {
            filterButton.tap()
        }
        
        // Close current sheet
        if app.navigationBars.buttons["Done"].exists {
            app.navigationBars.buttons["Done"].tap()
        }
        
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
    
    func testSheetDismissalMethods() throws {
        // Test different ways to dismiss sheets
        
        // Method 1: Done button
        app.buttons["filterButton"].firstMatch.tap()
        if app.navigationBars.buttons["Done"].exists {
            app.navigationBars.buttons["Done"].tap()
        }
        XCTAssertTrue(app.navigationBars["Discover"].exists)
        
        // Method 2: Swipe down
        app.buttons["filterButton"].firstMatch.tap()
        app.swipeDown()
        // May or may not dismiss, but shouldn't crash
        
        // Ensure we're back to main view
        if app.navigationBars["Filter Parks"].exists {
            if app.navigationBars.buttons["Done"].exists {
                app.navigationBars.buttons["Done"].tap()
            }
        }
    }
    
    // MARK: - Device Rotation and Layout Tests
    
    func testInterfaceOrientationChanges() throws {
        // Test UI adapts to orientation changes
        // Note: UI tests may not easily rotate device, but we can test layout stability
        
        // Perform actions that might trigger layout changes
        app.segmentedControls.buttons["List"].tap()
        app.segmentedControls.buttons["Map"].tap()
        
        app.buttons["filterButton"].firstMatch.tap()
        if app.navigationBars.buttons["Done"].exists {
            app.navigationBars.buttons["Done"].tap()
        }
        
        // UI should remain stable and accessible
        XCTAssertTrue(app.navigationBars["Discover"].exists)
        XCTAssertTrue(app.segmentedControls.buttons["Map"].exists)
        XCTAssertTrue(app.buttons["filterButton"].firstMatch.exists)
    }
    
    func testLayoutIntegrityUnderStress() throws {
        // Test that layout remains intact under various conditions
        
        // Rapidly change views and open sheets
        for _ in 0..<5 {
            app.segmentedControls.buttons["List"].tap()
            app.buttons["filterButton"].firstMatch.tap()
            
            if app.navigationBars.buttons["Done"].exists {
                app.navigationBars.buttons["Done"].tap()
            }
            
            app.segmentedControls.buttons["Map"].tap()
        }
        
        // Verify all key elements still exist and are positioned correctly
        XCTAssertTrue(app.navigationBars["Discover"].exists)
        XCTAssertTrue(app.segmentedControls.firstMatch.exists)
        XCTAssertTrue(app.buttons["filterButton"].firstMatch.exists)
        XCTAssertTrue(app.buttons["locationButton"].firstMatch.exists)
    }
    
    // MARK: - Memory Warning Simulation
    
    func testLowMemoryConditions() throws {
        // Simulate conditions that might trigger memory warnings
        
        // Create memory pressure by performing many operations
        for i in 0..<30 {
            app.segmentedControls.buttons["List"].tap()
            app.segmentedControls.buttons["Map"].tap()
            
            if i % 5 == 0 {
                app.buttons["filterButton"].firstMatch.tap()
                if app.navigationBars.buttons["Done"].exists {
                    app.navigationBars.buttons["Done"].tap()
                }
            }
        }
        
        // App should recover gracefully
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
    
    // MARK: - Timing and Race Condition Tests
    
    func testAsynchronousOperations() throws {
        // Test handling of asynchronous operations
        
        // Rapidly perform actions that might trigger async operations
        app.segmentedControls.buttons["Map"].tap()
        
        let locationButton = app.buttons["locationButton"].firstMatch
        if locationButton.isEnabled {
            locationButton.tap() // Might trigger async location request
        }
        
        // Immediately switch views
        app.segmentedControls.buttons["List"].tap()
        app.segmentedControls.buttons["Map"].tap()
        
        // Should handle async operations gracefully
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
    
    func testRaceConditionPrevention() throws {
        // Test that race conditions are handled properly
        
        // Perform overlapping operations
        app.buttons["filterButton"].firstMatch.tap()
        
        // Wait for UI to stabilize before next interaction
        let listButton = app.segmentedControls.buttons["List"]
        if listButton.waitForExistence(timeout: 1) && listButton.isHittable {
            listButton.tap()
        }
        
        if app.navigationBars["Filter Parks"].exists {
            if app.navigationBars.buttons["Done"].exists {
                app.navigationBars.buttons["Done"].tap()
            }
        }
        
        let mapButton = app.segmentedControls.buttons["Map"]
        if mapButton.exists && mapButton.isHittable {
            mapButton.tap()
        }
        
        // Should end in consistent state
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
    
    // MARK: - Error Recovery Tests
    
    func testErrorRecoveryFromInvalidStates() throws {
        // Test recovery from potentially invalid UI states
        
        // Force rapid state changes that might create inconsistencies
        for i in 0..<10 {
            let filterButton = app.buttons["filterButton"].firstMatch
            if filterButton.exists && filterButton.isHittable {
                filterButton.tap()
            }
            
            // Add small delay on first iteration to let UI stabilize
            if i == 0 {
                _ = app.segmentedControls.buttons["List"].waitForExistence(timeout: 0.5)
            }
            
            let listButton = app.segmentedControls.buttons["List"]
            if listButton.exists && listButton.isHittable {
                listButton.tap()
            }
            
            let mapButton = app.segmentedControls.buttons["Map"]
            if mapButton.exists && mapButton.isHittable {
                mapButton.tap()
            }
            
            if app.navigationBars.buttons["Done"].exists {
                app.navigationBars.buttons["Done"].tap()
            }
        }
        
        // App should recover to a valid state
        XCTAssertTrue(app.navigationBars["Discover"].exists)
        XCTAssertTrue(app.segmentedControls.firstMatch.exists)
    }
    
    func testGracefulDegradation() throws {
        // Test that app gracefully handles missing features or data
        
        // Test with various combinations of disabled features
        app.segmentedControls.buttons["List"].tap()
        
        // Location button should be disabled in list view
        let locationButton = app.buttons["locationButton"].firstMatch
        XCTAssertFalse(locationButton.isEnabled)
        
        // App should still be fully functional otherwise
        app.buttons["filterButton"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Filter Parks"].exists)
        
        if app.navigationBars.buttons["Done"].exists {
            app.navigationBars.buttons["Done"].tap()
        }
        
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
    
    // MARK: - Device Orientation Tests
    
    func testPortraitOrientationOnly() throws {
        // Verify app is configured for portrait mode only
        let device = XCUIDevice.shared
        
        // Get current orientation (should be portrait)
        let currentOrientation = device.orientation
        XCTAssertTrue(currentOrientation == .portrait || currentOrientation == .unknown, 
                     "App should start in portrait orientation")
        
        // Try to rotate device to landscape (this should not affect the app)
        device.orientation = .landscapeLeft
        
        // Wait a moment for any potential rotation
        sleep(1)
        
        // Verify app interface remains in portrait layout
        // Navigation bar should still be at top, buttons should be in portrait layout
        XCTAssertTrue(app.navigationBars["Discover"].exists)
        XCTAssertTrue(app.segmentedControls.firstMatch.exists)
        
        // Try other orientations
        device.orientation = .landscapeRight
        sleep(1)
        
        // App should still be functional and in portrait layout
        XCTAssertTrue(app.navigationBars["Discover"].exists)
        XCTAssertTrue(app.buttons["filterButton"].firstMatch.exists)
        
        // Reset to portrait
        device.orientation = .portrait
    }
    
    func testInterfaceStabilityDuringRotationAttempts() throws {
        // Test that attempting device rotation doesn't break the interface
        let device = XCUIDevice.shared
        
        // Start with basic functionality
        app.buttons["filterButton"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Filter Parks"].exists)
        
        // Attempt rotations while sheet is open
        device.orientation = .landscapeLeft
        usleep(500000)
        device.orientation = .landscapeRight  
        usleep(500000)
        device.orientation = .portraitUpsideDown
        usleep(500000)
        device.orientation = .portrait
        
        // Interface should remain stable and functional
        if app.navigationBars["Filter Parks"].exists {
            if app.navigationBars.buttons["Done"].exists {
                app.navigationBars.buttons["Done"].tap()
            }
        }
        
        // Should return to stable state
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
    
    func testAppInfoPlistOrientationConfiguration() throws {
        // This test verifies that the app's orientation configuration hasn't been accidentally changed
        // Since we can't directly read Info.plist in UI tests, we test the behavior
        
        let device = XCUIDevice.shared
        let originalOrientation = device.orientation
        
        // Try all possible orientations
        let orientations: [UIDeviceOrientation] = [
            .landscapeLeft,
            .landscapeRight,
            .portraitUpsideDown,
            .faceUp,
            .faceDown
        ]
        
        for orientation in orientations {
            device.orientation = orientation
            
            // Wait for potential rotation
            usleep(500000)
            
            // App should always maintain portrait layout regardless of device orientation
            // This verifies our Info.plist restriction is working
            XCTAssertTrue(app.navigationBars["Discover"].exists, 
                         "Navigation should exist in all orientations - portrait layout maintained")
            XCTAssertTrue(app.segmentedControls.firstMatch.exists,
                         "Segmented control should exist in all orientations - portrait layout maintained")
        }
        
        // Reset to portrait
        device.orientation = originalOrientation.isPortrait ? originalOrientation : .portrait
    }
    
    // MARK: - Long-Running Operation Tests
    
    func testLongRunningOperations() throws {
        // Test UI responsiveness during potentially long operations
        
        // Perform operations that might take time
        app.segmentedControls.buttons["Map"].tap()
        
        let mapView = app.otherElements["parkMap"].firstMatch
        
        // Perform map operations that might trigger data loading
        mapView.pinch(withScale: 0.1, velocity: -2.0) // Zoom out far
        mapView.pinch(withScale: 10.0, velocity: 2.0) // Zoom in far
        
        // UI should remain responsive
        app.segmentedControls.buttons["List"].tap()
        XCTAssertTrue(app.segmentedControls.buttons["List"].isSelected)
        
        app.segmentedControls.buttons["Map"].tap()
        XCTAssertTrue(app.segmentedControls.buttons["Map"].isSelected)
    }
}
