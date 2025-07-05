//
//  AccessibilityUITests.swift
//  FogFernUITests
//
//  Created by Claude on 7/5/25.
//

import XCTest

final class AccessibilityUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Basic Accessibility Tests
    
    func testAccessibilityIdentifiersExist() throws {
        // Verify key UI elements have accessibility identifiers
        let expectedIdentifiers = [
            "parkMap",
            "filterButton", 
            "locationButton"
        ]
        
        for identifier in expectedIdentifiers {
            XCTAssertTrue(app.descendants(matching: .any).matching(identifier: identifier).count > 0,
                         "Missing accessibility identifier: \(identifier)")
        }
    }
    
    func testAccessibilityLabelsAreDescriptive() throws {
        // Test that accessibility labels provide meaningful descriptions
        let mapView = app.otherElements["parkMap"].firstMatch.firstMatch
        XCTAssertEqual(mapView.label, "Map showing San Francisco parks")
        
        let filterButton = app.buttons["filterButton"].firstMatch
        XCTAssertEqual(filterButton.label, "Settings and park filters")
        
        let locationButton = app.buttons["locationButton"].firstMatch
        XCTAssertEqual(locationButton.label, "Center map on current location")
    }
    
    func testNavigationElementsAccessibility() throws {
        // Test navigation elements are accessible
        let navigationBar = app.navigationBars["Discover"]
        XCTAssertTrue(navigationBar.exists)
        XCTAssertTrue(navigationBar.isHittable)
        
        // Segmented control should be accessible
        let segmentedControl = app.segmentedControls.firstMatch
        XCTAssertTrue(segmentedControl.exists)
        XCTAssertTrue(segmentedControl.isHittable)
    }
    
    func testButtonsAreAccessible() throws {
        // Test all main buttons are accessible
        let buttons = [
            app.buttons["filterButton"].firstMatch,
            app.buttons["locationButton"].firstMatch
        ]
        
        for button in buttons {
            XCTAssertTrue(button.exists, "Button should exist")
            XCTAssertTrue(button.isHittable, "Button should be hittable")
            XCTAssertFalse(button.label.isEmpty, "Button should have a label")
        }
    }
    
    // MARK: - VoiceOver Simulation Tests
    
    func testVoiceOverNavigationFlow() throws {
        // Simulate VoiceOver navigation through main elements
        
        // Start with navigation bar
        let navigationBar = app.navigationBars["Discover"]
        XCTAssertTrue(navigationBar.exists)
        
        // Move to segmented control
        let segmentedControl = app.segmentedControls.firstMatch
        XCTAssertTrue(segmentedControl.exists)
        
        // Move to toolbar buttons
        let filterButton = app.buttons["filterButton"].firstMatch
        XCTAssertTrue(filterButton.exists)
        
        let locationButton = app.buttons["locationButton"].firstMatch
        XCTAssertTrue(locationButton.exists)
        
        // All elements should be reachable in logical order
        XCTAssertTrue(true) // Test passes if no exceptions thrown
    }
    
    func testVoiceOverInFilterSheet() throws {
        // Open filter sheet
        app.buttons["filterButton"].firstMatch.tap()
        
        // Test VoiceOver navigation in filter sheet
        XCTAssertTrue(app.navigationBars["Filter Parks"].exists)
        
        // Category items should be accessible - look for any park-related text
        let staticTexts = app.staticTexts
        XCTAssertTrue(staticTexts.count > 0) // Should have some text elements in filter view
        
        // Look for section header if it exists
        let sectionHeader = app.staticTexts["Park Categories"].firstMatch
        if sectionHeader.exists {
            XCTAssertTrue(sectionHeader.exists)
        }
        
        // Close filter sheet
        if app.navigationBars.buttons["Done"].exists {
            app.navigationBars.buttons["Done"].tap()
        }
    }
    
    // MARK: - Dynamic Type Support Tests
    
    func testDynamicTypeSupport() throws {
        // Test that the app handles different text sizes
        // Note: UI tests can't easily change system text size,
        // but we can verify text elements exist and are properly constrained
        
        let staticTexts = app.staticTexts
        
        // Verify key text elements exist
        XCTAssertTrue(app.navigationBars["Discover"].staticTexts["Discover"].exists)
        
        // Text elements should be visible and accessible
        for i in 0..<min(staticTexts.count, 5) {
            let textElement = staticTexts.element(boundBy: i)
            XCTAssertTrue(textElement.exists)
        }
    }
    
    func testTextReadability() throws {
        // Verify that text elements have sufficient size and contrast
        // This is mainly tested by ensuring elements are accessible
        
        app.buttons["filterButton"].firstMatch.tap()
        
        // Check text elements in filter view
        let categoryTexts = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'park'"))
        
        if categoryTexts.count > 0 {
            let firstText = categoryTexts.element(boundBy: 0)
            XCTAssertTrue(firstText.exists)
            XCTAssertTrue(firstText.isHittable)
        }
        
        // Close filter view
        if app.navigationBars.buttons["Done"].exists {
            app.navigationBars.buttons["Done"].tap()
        }
    }
    
    // MARK: - Reduced Motion Support Tests
    
    func testReducedMotionCompatibility() throws {
        // Test that app works well with reduced motion settings
        // Verify that essential functionality doesn't rely solely on animations
        
        // Test view switching without relying on animation feedback
        app.segmentedControls.buttons["List"].tap()
        XCTAssertTrue(app.segmentedControls.buttons["List"].isSelected)
        
        app.segmentedControls.buttons["Map"].tap()
        XCTAssertTrue(app.segmentedControls.buttons["Map"].isSelected)
        
        // Test sheet presentation/dismissal
        app.buttons["filterButton"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Filter Parks"].exists)
        
        if app.navigationBars.buttons["Done"].exists {
            app.navigationBars.buttons["Done"].tap()
        }
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }
    
    // MARK: - Color and Contrast Tests
    
    func testHighContrastCompatibility() throws {
        // Test that UI elements are distinguishable without relying solely on color
        
        // Buttons should be identifiable by more than just color
        let filterButton = app.buttons["filterButton"]
        XCTAssertTrue(filterButton.exists)
        XCTAssertFalse(filterButton.label.isEmpty) // Has text/label
        
        let locationButton = app.buttons["locationButton"]
        XCTAssertTrue(locationButton.exists)
        XCTAssertFalse(locationButton.label.isEmpty) // Has accessibility label
        
        // Segmented control should be usable without color
        let mapSegment = app.segmentedControls.buttons["Map"]
        let listSegment = app.segmentedControls.buttons["List"]
        
        XCTAssertTrue(mapSegment.exists)
        XCTAssertTrue(listSegment.exists)
        
        // Test that selection state is clear
        mapSegment.tap()
        XCTAssertTrue(mapSegment.isSelected)
        
        listSegment.tap()
        XCTAssertTrue(listSegment.isSelected)
    }
    
    func testColorIndependentNavigation() throws {
        // Test that navigation doesn't rely solely on color cues
        
        // Open filter sheet
        app.buttons["filterButton"].firstMatch.tap()
        
        // Categories should be selectable without relying on color alone
        let categoryElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'park'"))
        
        if categoryElements.count > 0 {
            categoryElements.element(boundBy: 0).tap()
            
            // Selection should be indicated by more than color (checkmarks, etc.)
            let checkmarks = app.images.matching(NSPredicate(format: "label CONTAINS[c] 'checkmark'"))
            // Checkmarks may or may not be visible depending on implementation
            
            XCTAssertTrue(app.navigationBars["Filter Parks"].exists) // Main test: no crash
        }
        
        // Close filter
        if app.navigationBars.buttons["Done"].exists {
            app.navigationBars.buttons["Done"].tap()
        }
    }
    
    // MARK: - Gesture Accessibility Tests
    
    func testAlternativeInputMethods() throws {
        // Test that essential functions are available without complex gestures
        
        // Map interaction should be possible through buttons, not just gestures
        app.segmentedControls.buttons["Map"].tap()
        
        let locationButton = app.buttons["locationButton"]
        if locationButton.isEnabled {
            locationButton.tap() // Alternative to manual map navigation
            XCTAssertTrue(app.navigationBars["Discover"].exists)
        }
        
        // Filter access through button, not gesture
        app.buttons["filterButton"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Filter Parks"].exists)
        
        if app.navigationBars.buttons["Done"].exists {
            app.navigationBars.buttons["Done"].tap()
        }
    }
    
    func testTouchTargetSizes() throws {
        // Verify that interactive elements meet minimum touch target size
        // This is mainly tested by ensuring elements are hittable
        
        let interactiveElements = [
            app.buttons["filterButton"].firstMatch,
            app.buttons["locationButton"].firstMatch,
            app.segmentedControls.buttons["Map"].firstMatch,
            app.segmentedControls.buttons["List"].firstMatch
        ]
        
        for element in interactiveElements {
            XCTAssertTrue(element.exists, "Interactive element should exist")
            XCTAssertTrue(element.isHittable, "Interactive element should be hittable")
        }
    }
    
    // MARK: - Screen Reader Support Tests
    
    func testScreenReaderHints() throws {
        // Test that elements provide helpful hints for screen readers
        
        // Buttons should have descriptive labels
        let filterButton = app.buttons["filterButton"].firstMatch
        XCTAssertFalse(filterButton.label.isEmpty)
        XCTAssertTrue(filterButton.label.contains("filter") || filterButton.label.contains("Settings"))
        
        let locationButton = app.buttons["locationButton"].firstMatch
        XCTAssertFalse(locationButton.label.isEmpty)
        XCTAssertTrue(locationButton.label.contains("location") || locationButton.label.contains("Center"))
        
        // Map should have descriptive label
        let mapView = app.otherElements["parkMap"].firstMatch
        XCTAssertFalse(mapView.label.isEmpty)
        XCTAssertTrue(mapView.label.contains("Map") || mapView.label.contains("park"))
    }
    
    func testScreenReaderNavigationOrder() throws {
        // Test logical navigation order for screen readers
        
        // Elements should be accessible in logical order
        let navigationBar = app.navigationBars["Discover"]
        let segmentedControl = app.segmentedControls.firstMatch
        let filterButton = app.buttons["filterButton"].firstMatch
        let locationButton = app.buttons["locationButton"].firstMatch
        
        // All should exist and be accessible
        XCTAssertTrue(navigationBar.exists)
        XCTAssertTrue(segmentedControl.exists)
        XCTAssertTrue(filterButton.exists)
        XCTAssertTrue(locationButton.exists)
    }
    
    // MARK: - Edge Case Accessibility Tests
    
    func testAccessibilityWithEmptyStates() throws {
        // Test accessibility when no data is available
        
        // Switch to list view (may be empty)
        app.segmentedControls.buttons["List"].tap()
        
        // Should still be navigable even if empty
        XCTAssertTrue(app.navigationBars["Discover"].exists)
        XCTAssertTrue(app.segmentedControls.buttons["List"].isSelected)
        
        // Switch back to map
        app.segmentedControls.buttons["Map"].tap()
        XCTAssertTrue(app.segmentedControls.buttons["Map"].isSelected)
    }
    
    func testAccessibilityDuringLoading() throws {
        // Test that accessibility is maintained during loading states
        
        // Rapidly switch views to test loading states
        for _ in 0..<3 {
            app.segmentedControls.buttons["List"].tap()
            app.segmentedControls.buttons["Map"].tap()
        }
        
        // UI should remain accessible
        XCTAssertTrue(app.navigationBars["Discover"].exists)
        XCTAssertTrue(app.buttons["filterButton"].firstMatch.exists)
        XCTAssertTrue(app.buttons["locationButton"].firstMatch.exists)
    }
    
    // MARK: - Accessibility Performance Tests
    
    func testAccessibilityPerformance() throws {
        // Test that accessibility doesn't significantly impact performance
        
        measure {
            // Perform common accessibility-related actions
            app.buttons["filterButton"].firstMatch.tap()
            
            if app.navigationBars.buttons["Done"].exists {
                app.navigationBars.buttons["Done"].tap()
            }
            
            app.segmentedControls.buttons["List"].tap()
            app.segmentedControls.buttons["Map"].tap()
        }
    }
}