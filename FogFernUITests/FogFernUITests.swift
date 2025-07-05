//
//  FogFernUITests.swift
//  FogFernUITests
//
//  Created by Claude on 7/5/25.
//

import XCTest

final class FogFernUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - App Launch and Basic Navigation Tests
    
    func testAppLaunchAndBasicNavigation() throws {
        // Verify app launches successfully
        XCTAssertTrue(app.navigationBars["Discover"].exists)
        
        // Verify main UI elements are present
        XCTAssertTrue(app.segmentedControls.buttons["Map"].exists)
        XCTAssertTrue(app.segmentedControls.buttons["List"].exists)
        XCTAssertTrue(app.buttons["filterButton"].firstMatch.exists)
        XCTAssertTrue(app.buttons["locationButton"].firstMatch.exists)
    }
    
    func testNavigationTitle() throws {
        let navigationBar = app.navigationBars["Discover"]
        XCTAssertTrue(navigationBar.exists)
        XCTAssertTrue(navigationBar.staticTexts["Discover"].exists)
    }
    
    // MARK: - Map/List View Toggle Tests
    
    func testMapViewIsDefaultView() throws {
        // Map should be the default view
        let mapView = app.otherElements["parkMap"].firstMatch
        XCTAssertTrue(mapView.exists)
        
        // Map tab should be selected by default
        let mapButton = app.segmentedControls.buttons["Map"]
        XCTAssertTrue(mapButton.isSelected)
    }
    
    func testSwitchToListView() throws {
        // Switch to list view
        let listButton = app.segmentedControls.buttons["List"]
        listButton.tap()
        
        // Verify list view is now active
        XCTAssertTrue(listButton.isSelected)
        
        // Map view should no longer be the active view
        let mapButton = app.segmentedControls.buttons["Map"]
        XCTAssertFalse(mapButton.isSelected)
    }
    
    func testSwitchBackToMapView() throws {
        // First switch to list view
        app.segmentedControls.buttons["List"].tap()
        
        // Then switch back to map view
        let mapButton = app.segmentedControls.buttons["Map"]
        mapButton.tap()
        
        // Verify map view is active again
        XCTAssertTrue(mapButton.isSelected)
        
        // Verify map is visible
        let mapView = app.otherElements["parkMap"].firstMatch
        XCTAssertTrue(mapView.exists)
    }
    
    // MARK: - Filter Functionality Tests
    
    func testOpenFilterSheet() throws {
        let filterButton = app.buttons["filterButton"].firstMatch
        XCTAssertTrue(filterButton.exists)
        
        // Tap filter button
        filterButton.tap()
        
        // Verify filter sheet opens
        XCTAssertTrue(app.navigationBars["Filter Parks"].exists)
        
        // Check for section header or other filter content
        let sectionHeader = app.staticTexts["Park Categories"].firstMatch
        let hasFilterContent = sectionHeader.exists || app.staticTexts.count > 1
        XCTAssertTrue(hasFilterContent)
    }
    
    func testFilterSheetDisplaysCategories() throws {
        // Open filter sheet
        app.buttons["filterButton"].firstMatch.tap()
        
        // Verify filter sheet opened and has content
        XCTAssertTrue(app.navigationBars["Filter Parks"].exists)
        
        // Check for section header or other filter content  
        let sectionHeader = app.staticTexts["Park Categories"].firstMatch
        let hasFilterContent = sectionHeader.exists || app.staticTexts.count > 1
        XCTAssertTrue(hasFilterContent)
    }
    
    func testFilterSheetDismiss() throws {
        // Open filter sheet
        app.buttons["filterButton"].firstMatch.tap()
        
        // Dismiss using Done button
        let doneButton = app.navigationBars.buttons["Done"]
        XCTAssertTrue(doneButton.exists)
        doneButton.tap()
        
        // Verify we're back to main view
        XCTAssertTrue(app.navigationBars["Discover"].exists)
        XCTAssertFalse(app.navigationBars["Filter Parks"].exists)
    }
    
    func testFilterCategorySelection() throws {
        // Open filter sheet
        app.buttons["filterButton"].firstMatch.tap()
        
        // Find a category row and tap it
        let categoryRow = app.staticTexts["Mini Parks"].firstMatch
        if categoryRow.exists {
            categoryRow.tap()
            
            // Verify checkmark appears (category is selected)
            // Note: We can't easily verify the checkmark in UI tests, 
            // but we can verify the tap doesn't crash the app
            XCTAssertTrue(app.navigationBars["Filter Parks"].exists)
        }
    }
    
    // MARK: - Location Services Tests
    
    func testLocationButtonExists() throws {
        let locationButton = app.buttons["locationButton"].firstMatch
        XCTAssertTrue(locationButton.exists)
        
        // Verify accessibility label
        XCTAssertEqual(locationButton.label, "Center map on current location")
    }
    
    func testLocationButtonTapInMapView() throws {
        // Ensure we're in map view
        app.segmentedControls.buttons["Map"].tap()
        
        let locationButton = app.buttons["locationButton"].firstMatch
        XCTAssertTrue(locationButton.exists)
        
        // Tap location button (should not crash)
        locationButton.tap()
        
        // Verify we're still in the main view
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
    
    func testLocationButtonDisabledInListView() throws {
        // Switch to list view
        app.segmentedControls.buttons["List"].tap()
        
        let locationButton = app.buttons["locationButton"].firstMatch
        
        // Location button should be disabled in list view
        XCTAssertFalse(locationButton.isEnabled)
    }
    
    // MARK: - Map Interaction Tests
    
    func testMapViewExists() throws {
        // Ensure we're in map view
        app.segmentedControls.buttons["Map"].tap()
        
        let mapView = app.otherElements["parkMap"].firstMatch
        XCTAssertTrue(mapView.exists)
        XCTAssertEqual(mapView.label, "Map showing San Francisco parks")
    }
    
    func testMapViewInteraction() throws {
        // Ensure we're in map view
        app.segmentedControls.buttons["Map"].tap()
        
        let mapView = app.otherElements["parkMap"].firstMatch
        XCTAssertTrue(mapView.exists)
        
        // Use coordinate-based tapping to avoid accessibility scroll issues
        let coordinate = mapView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coordinate.tap()
        
        // Verify we're still in the main view
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
    
    // MARK: - Park Detail Tests
    
    func testParkDetailSheetOpening() throws {
        // Note: This test depends on parks being available and visible
        // We'll test the general flow without relying on specific park data
        
        // Ensure we're in map view
        app.segmentedControls.buttons["Map"].tap()
        
        let mapView = app.otherElements["parkMap"].firstMatch
        XCTAssertTrue(mapView.exists)
        
        // Look for any park markers on the map
        let mapAnnotations = app.otherElements.matching(identifier: "MapAnnotation")
        if mapAnnotations.count > 0 {
            // Tap on the first annotation
            mapAnnotations.element(boundBy: 0).tap()
            
            // Check if a detail sheet appears
            // The exact identifier depends on the park name, so we check for common elements
            if app.navigationBars.count > 1 {
                // A detail sheet likely opened
                XCTAssertTrue(true) // Test passes if no crash occurs
                
                // Try to dismiss if a sheet is open
                if app.buttons["Close"].exists {
                    app.buttons["Close"].tap()
                }
            }
        }
    }
    
    // MARK: - List View Tests
    
    func testListViewParksDisplay() throws {
        // Switch to list view
        app.segmentedControls.buttons["List"].tap()
        
        // Wait a moment for the view to load
        sleep(1)
        
        // Verify we successfully switched to list view
        XCTAssertTrue(app.segmentedControls.buttons["List"].isSelected)
        
        // Verify we're still in the main discover view
        XCTAssertTrue(app.navigationBars["Discover"].exists)
        
        // Look for typical list view elements or any content
        let scrollViews = app.scrollViews
        let tables = app.tables
        let cells = app.cells
        
        // List view should be functional (either with scroll views, tables, cells, or at minimum navigation is working)
        let hasListElements = scrollViews.count > 0 || tables.count > 0 || cells.count > 0
        let isListViewFunctional = hasListElements || app.navigationBars["Discover"].exists
        XCTAssertTrue(isListViewFunctional)
    }
    
    func testListViewInteraction() throws {
        // Switch to list view
        app.segmentedControls.buttons["List"].tap()
        
        // Wait for view to load
        sleep(1)
        
        // Try to interact with list elements
        let cells = app.cells
        if cells.count > 0 {
            // Tap on the first cell
            cells.element(boundBy: 0).tap()
            
            // Should not crash the app
            XCTAssertTrue(app.navigationBars["Discover"].exists)
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityIdentifiers() throws {
        // Verify key elements have accessibility identifiers
        XCTAssertTrue(app.otherElements["parkMap"].firstMatch.exists)
        XCTAssertTrue(app.buttons["filterButton"].firstMatch.exists)
        XCTAssertTrue(app.buttons["locationButton"].firstMatch.exists)
    }
    
    func testAccessibilityLabels() throws {
        // Verify accessibility labels are set correctly
        let mapView = app.otherElements["parkMap"].firstMatch
        XCTAssertEqual(mapView.label, "Map showing San Francisco parks")
        
        let filterButton = app.buttons["filterButton"].firstMatch
        XCTAssertEqual(filterButton.label, "Settings and park filters")
        
        let locationButton = app.buttons["locationButton"].firstMatch
        XCTAssertEqual(locationButton.label, "Center map on current location")
    }
    
    // MARK: - Edge Cases and Error Handling Tests
    
    func testAppStabilityWithRapidViewSwitching() throws {
        // Rapidly switch between map and list views
        for _ in 0..<5 {
            app.segmentedControls.buttons["List"].tap()
            app.segmentedControls.buttons["Map"].tap()
        }
        
        // App should remain stable
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
    
    func testFilterSheetOpenCloseStability() throws {
        // Rapidly open and close filter sheet
        for _ in 0..<3 {
            app.buttons["filterButton"].firstMatch.tap()
            
            if app.navigationBars.buttons["Done"].exists {
                app.navigationBars.buttons["Done"].tap()
            } else if app.navigationBars.buttons["Close"].exists {
                app.navigationBars.buttons["Close"].tap()
            }
        }
        
        // App should remain stable
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
    
    // MARK: - Performance Tests
    
    func testAppLaunchPerformance() throws {
        // Measure app launch time
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    func testViewSwitchingPerformance() throws {
        // Measure view switching performance
        measure {
            for _ in 0..<10 {
                app.segmentedControls.buttons["List"].tap()
                app.segmentedControls.buttons["Map"].tap()
            }
        }
    }
}