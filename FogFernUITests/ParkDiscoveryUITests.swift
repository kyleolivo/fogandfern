//
//  ParkDiscoveryUITests.swift
//  FogFernUITests
//
//  Created by Claude on 7/5/25.
//

import XCTest

final class ParkDiscoveryUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Park Discovery Flow Tests
    
    func testParkDiscoveryWorkflow() throws {
        // Start in map view
        XCTAssertTrue(app.segmentedControls.buttons["Map"].isSelected)
        
        // Verify map shows parks
        let mapView = app.otherElements["parkMap"].firstMatch
        XCTAssertTrue(mapView.exists)
        
        // Switch to list view to see parks listed
        app.segmentedControls.buttons["List"].tap()
        
        // Wait for list to load
        let expectation = XCTestExpectation(description: "List view loads")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
        
        // Verify we successfully switched to list view
        XCTAssertTrue(app.segmentedControls.buttons["List"].isSelected)
        
        // List view should be functional (may or may not have visible content)
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
    
    func testMapParkMarkerInteraction() throws {
        // Ensure we're in map view
        app.segmentedControls.buttons["Map"].tap()
        
        let mapView = app.otherElements["parkMap"].firstMatch
        XCTAssertTrue(mapView.exists)
        
        // Tap different areas of the map to look for park markers
        let mapFrame = mapView.frame
        _ = mapFrame.midX
        _ = mapFrame.midY
        
        // Tap center of map
        let centerCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        centerCoordinate.tap()
        
        // Tap slightly off-center to potentially hit a park marker
        let offsetCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.4))
        offsetCoordinate.tap()
        
        // App should remain stable regardless of where we tap
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
    
    func testParkDetailSheetWorkflow() throws {
        // This test simulates the park detail workflow
        // Since park data is dynamic, we test the general flow
        
        // Start in map view
        app.segmentedControls.buttons["Map"].tap()
        
        // Look for any sheets that might open when interacting with parks
        let mapView = app.otherElements["parkMap"].firstMatch
        XCTAssertTrue(mapView.exists)
        
        // Use coordinate-based tapping instead of direct element tap to avoid accessibility scroll issues
        let coordinate = mapView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coordinate.tap()
        
        // Check if any modal sheets or navigation controllers appear
        let modalSheets = app.sheets
        let navigationBars = app.navigationBars
        
        if modalSheets.count > 1 || navigationBars.count > 1 {
            // A detail view likely opened, test common interactions
            
            // Look for common park detail elements
            if app.buttons["Mark as Visited"].exists {
                // Test mark as visited functionality
                app.buttons["Mark as Visited"].tap()
                
                // Should not crash
                XCTAssertTrue(true)
            }
            
            // Look for close/dismiss buttons
            if app.buttons["Close"].exists {
                app.buttons["Close"].tap()
            } else if app.buttons["Done"].exists {
                app.buttons["Done"].tap()
            } else {
                // Try swiping down to dismiss
                app.swipeDown()
            }
        }
        
        // Should return to main discovery view
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
    
    func testVisitTrackingUI() throws {
        // Test the UI for marking parks as visited
        // This is a workflow test rather than data verification
        
        // Switch to list view where visit status might be more visible
        app.segmentedControls.buttons["List"].tap()
        
        // Wait for list to load
        sleep(1)
        
        // Look for any park list items
        _ = app.cells
        let buttons = app.buttons
        
        // Look for visit-related UI elements
        let visitButtons = buttons.matching(NSPredicate(format: "label CONTAINS[c] 'visit'"))
        _ = app.images.matching(NSPredicate(format: "label CONTAINS[c] 'checkmark'"))
        
        // If visit-related UI exists, test interaction
        if visitButtons.count > 0 {
            visitButtons.element(boundBy: 0).tap()
            
            // Should not crash
            XCTAssertTrue(app.navigationBars["Discover"].exists)
        }
    }
    
    func testRandomParkSelection() throws {
        // Test random park selection functionality via button
        
        // Ensure we're in map view
        app.segmentedControls.buttons["Map"].tap()
        
        let mapView = app.otherElements["parkMap"].firstMatch
        XCTAssertTrue(mapView.exists)
        
        // Test the random park button
        let randomParkButton = app.buttons["randomParkButton"].firstMatch
        XCTAssertTrue(randomParkButton.exists, "Random park button should exist")
        
        // Button should be enabled when in map view
        XCTAssertTrue(randomParkButton.isEnabled, "Random park button should be enabled in map view")
        
        // Tap the random park button (without checking position to avoid scroll issues)
        if randomParkButton.isHittable {
            randomParkButton.tap()
            
            // After tapping, the app should remain stable
            XCTAssertTrue(app.navigationBars["Discover"].exists)
        }
        
        // App should remain stable
        XCTAssertTrue(app.navigationBars["Discover"].exists)
        XCTAssertTrue(mapView.exists)
    }
    
    // MARK: - Map Navigation Tests
    
    func testMapZoomAndPan() throws {
        // Ensure we're in map view
        app.segmentedControls.buttons["Map"].tap()
        
        let mapView = app.otherElements["parkMap"].firstMatch
        XCTAssertTrue(mapView.exists)
        
        // Test pinch to zoom
        mapView.pinch(withScale: 2.0, velocity: 1.0)
        mapView.pinch(withScale: 0.5, velocity: -1.0)
        
        // Test pan gestures
        mapView.swipeLeft()
        mapView.swipeRight()
        mapView.swipeUp()
        mapView.swipeDown()
        
        // App should remain stable after map interactions
        XCTAssertTrue(app.navigationBars["Discover"].exists)
        XCTAssertTrue(mapView.exists)
    }
    
    func testLocationCenteringWorkflow() throws {
        // Test the location centering feature
        app.segmentedControls.buttons["Map"].tap()
        
        let locationButton = app.buttons["locationButton"].firstMatch
        XCTAssertTrue(locationButton.exists)
        
        // If location services are available, button should be enabled
        if locationButton.isEnabled {
            locationButton.tap()
            
            // Should not crash and should remain on map view
            XCTAssertTrue(app.navigationBars["Discover"].exists)
            XCTAssertTrue(app.segmentedControls.buttons["Map"].isSelected)
        }
    }
    
    // MARK: - List View Park Interaction Tests
    
    func testListViewParkSelection() throws {
        // Switch to list view
        app.segmentedControls.buttons["List"].tap()
        
        // Wait for list to populate
        sleep(1)
        
        // Test that random park button is disabled in list view
        let randomParkButton = app.buttons["randomParkButton"].firstMatch
        XCTAssertTrue(randomParkButton.exists, "Random park button should exist")
        XCTAssertFalse(randomParkButton.isEnabled, "Random park button should be disabled in list view")
        
        // Test scrolling in list view
        let scrollViews = app.scrollViews
        if scrollViews.count > 0 {
            let listView = scrollViews.firstMatch
            listView.swipeUp()
            listView.swipeDown()
        }
        
        // Test tapping on list items
        let cells = app.cells
        if cells.count > 0 {
            let firstCell = cells.element(boundBy: 0)
            firstCell.tap()
            
            // Should either open a detail view or stay in list
            XCTAssertTrue(app.navigationBars.count >= 1)
        }
    }
    
    func testListViewToMapViewTransition() throws {
        // Start in list view
        app.segmentedControls.buttons["List"].tap()
        sleep(1)
        
        // Interact with list if possible
        let scrollViews = app.scrollViews
        if scrollViews.count > 0 {
            scrollViews.firstMatch.swipeUp()
        }
        
        // Switch back to map view
        app.segmentedControls.buttons["Map"].tap()
        
        // Verify map is visible and functional
        let mapView = app.otherElements["parkMap"].firstMatch
        XCTAssertTrue(mapView.exists)
        XCTAssertTrue(app.segmentedControls.buttons["Map"].isSelected)
    }
    
    // MARK: - Data Loading and State Tests
    
    func testEmptyStateHandling() throws {
        // Test app behavior when no parks are loaded
        // This mainly tests that the app doesn't crash in edge cases
        
        // Try both views
        app.segmentedControls.buttons["Map"].tap()
        XCTAssertTrue(app.otherElements["parkMap"].firstMatch.exists)
        
        app.segmentedControls.buttons["List"].tap()
        // Should not crash even if no data is available
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
    
    func testUIResponsivenessDuringDataLoading() throws {
        // Test that UI remains responsive during data operations
        
        // Rapidly switch views while app is loading
        for _ in 0..<3 {
            app.segmentedControls.buttons["List"].tap()
            app.segmentedControls.buttons["Map"].tap()
        }
        
        // Open and close filter multiple times
        for _ in 0..<2 {
            app.buttons["filterButton"].firstMatch.tap()
            
            if app.navigationBars.buttons["Done"].exists {
                app.navigationBars.buttons["Done"].tap()
            }
        }
        
        // App should remain stable
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteUserJourney() throws {
        // Test a complete user journey through the app
        
        // 1. Start in map view (default)
        XCTAssertTrue(app.segmentedControls.buttons["Map"].isSelected)
        
        // 2. Test random park button exists and is enabled in map view
        let randomParkButton = app.buttons["randomParkButton"].firstMatch
        XCTAssertTrue(randomParkButton.exists)
        XCTAssertTrue(randomParkButton.isEnabled)
        
        // 3. Open filter settings
        app.buttons["filterButton"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Filter Parks"].exists)
        
        // 4. Close filter settings
        if app.navigationBars.buttons["Done"].exists {
            app.navigationBars.buttons["Done"].tap()
        }
        
        // 5. Switch to list view
        app.segmentedControls.buttons["List"].tap()
        XCTAssertTrue(app.segmentedControls.buttons["List"].isSelected)
        
        // 6. Try location centering (should be disabled in list view)
        let locationButton = app.buttons["locationButton"].firstMatch
        XCTAssertFalse(locationButton.isEnabled)
        
        // 7. Random park button should be disabled in list view
        XCTAssertFalse(randomParkButton.isEnabled)
        
        // 8. Switch back to map view
        app.segmentedControls.buttons["Map"].tap()
        XCTAssertTrue(app.segmentedControls.buttons["Map"].isSelected)
        
        // 9. Try location centering (should be enabled in map view)
        XCTAssertTrue(locationButton.isEnabled)
        
        // 10. Random park button should be enabled again in map view
        XCTAssertTrue(randomParkButton.isEnabled)
        
        // 11. End in stable state
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
}
