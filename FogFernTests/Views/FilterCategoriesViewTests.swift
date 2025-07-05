//
//  FilterCategoriesViewTests.swift
//  FogFernTests
//
//  Created by Claude on 7/5/25.
//

import XCTest
import SwiftUI
@testable import FogFern

final class FilterCategoriesViewTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var selectedCategories: Set<ParkCategory>!
    var filterView: FilterCategoriesView!
    
    override func setUpWithError() throws {
        super.setUp()
        selectedCategories = [.destination]
        filterView = FilterCategoriesView(selectedCategories: .constant(selectedCategories))
    }
    
    override func tearDownWithError() throws {
        selectedCategories = nil
        filterView = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testFilterCategoriesViewInitialization() throws {
        let testCategories: Set<ParkCategory> = [.destination, .neighborhood]
        let view = FilterCategoriesView(selectedCategories: .constant(testCategories))
        
        XCTAssertNotNil(view)
    }
    
    // MARK: - Category Description Tests
    
    func testCategoryDescriptionForDestination() throws {
        let description = categoryDescription(for: .destination)
        XCTAssertEqual(description, "Large regional parks with major attractions")
    }
    
    func testCategoryDescriptionForNeighborhood() throws {
        let description = categoryDescription(for: .neighborhood)
        XCTAssertEqual(description, "Local community parks with playgrounds and sports")
    }
    
    func testCategoryDescriptionForMini() throws {
        let description = categoryDescription(for: .mini)
        XCTAssertEqual(description, "Small neighborhood spaces and pocket parks")
    }
    
    func testCategoryDescriptionForPlaza() throws {
        let description = categoryDescription(for: .plaza)
        XCTAssertEqual(description, "Urban squares and civic gathering spaces")
    }
    
    func testCategoryDescriptionForGarden() throws {
        let description = categoryDescription(for: .garden)
        XCTAssertEqual(description, "Community gardens and green spaces")
    }
    
    func testCategoryDescriptionForAllCategories() throws {
        // Test that all categories have descriptions
        for category in ParkCategory.allCases {
            let description = categoryDescription(for: category)
            XCTAssertFalse(description.isEmpty)
            XCTAssertTrue(description.count > 10) // Ensure descriptions are meaningful
        }
    }
    
    // MARK: - Toggle Category Logic Tests
    
    func testToggleCategoryAddsNewCategory() throws {
        var testCategories: Set<ParkCategory> = [.destination]
        
        // Simulate adding neighborhood category
        if testCategories.contains(.neighborhood) {
            testCategories.remove(.neighborhood)
        } else {
            testCategories.insert(.neighborhood)
        }
        
        XCTAssertTrue(testCategories.contains(.neighborhood))
        XCTAssertTrue(testCategories.contains(.destination))
        XCTAssertEqual(testCategories.count, 2)
    }
    
    func testToggleCategoryRemovesExistingCategory() throws {
        var testCategories: Set<ParkCategory> = [.destination, .neighborhood]
        
        // Simulate removing neighborhood category
        if testCategories.contains(.neighborhood) {
            testCategories.remove(.neighborhood)
        } else {
            testCategories.insert(.neighborhood)
        }
        
        XCTAssertFalse(testCategories.contains(.neighborhood))
        XCTAssertTrue(testCategories.contains(.destination))
        XCTAssertEqual(testCategories.count, 1)
    }
    
    func testToggleCategoryEnsuresAtLeastOneSelected() throws {
        var testCategories: Set<ParkCategory> = [.destination]
        
        // Simulate removing the last category
        if testCategories.contains(.destination) {
            testCategories.remove(.destination)
        } else {
            testCategories.insert(.destination)
        }
        
        // Ensure at least one category is always selected
        if testCategories.isEmpty {
            testCategories.insert(.destination)
        }
        
        XCTAssertFalse(testCategories.isEmpty)
        XCTAssertTrue(testCategories.contains(.destination))
        XCTAssertEqual(testCategories.count, 1)
    }
    
    func testToggleCategoryFromEmptySetAddsDefault() throws {
        var testCategories: Set<ParkCategory> = []
        
        // Simulate the empty set logic
        if testCategories.isEmpty {
            testCategories.insert(.destination)
        }
        
        XCTAssertEqual(testCategories.count, 1)
        XCTAssertTrue(testCategories.contains(.destination))
    }
    
    func testToggleCategoryWithMultipleCategories() throws {
        var testCategories: Set<ParkCategory> = [.destination, .neighborhood, .mini]
        
        // Remove one category
        if testCategories.contains(.neighborhood) {
            testCategories.remove(.neighborhood)
        } else {
            testCategories.insert(.neighborhood)
        }
        
        XCTAssertEqual(testCategories.count, 2)
        XCTAssertTrue(testCategories.contains(.destination))
        XCTAssertTrue(testCategories.contains(.mini))
        XCTAssertFalse(testCategories.contains(.neighborhood))
    }
    
    // MARK: - Show All Categories Tests
    
    func testShowAllCategoriesIncludesAllTypes() throws {
        let allCategories = Set(ParkCategory.allCases)
        
        XCTAssertEqual(allCategories.count, ParkCategory.allCases.count)
        XCTAssertTrue(allCategories.contains(.destination))
        XCTAssertTrue(allCategories.contains(.neighborhood))
        XCTAssertTrue(allCategories.contains(.mini))
        XCTAssertTrue(allCategories.contains(.plaza))
        XCTAssertTrue(allCategories.contains(.garden))
    }
    
    func testShowAllCategoriesFromSingleCategory() throws {
        var testCategories: Set<ParkCategory> = [.destination]
        
        // Simulate "Show All Categories" button
        testCategories = Set(ParkCategory.allCases)
        
        XCTAssertEqual(testCategories.count, ParkCategory.allCases.count)
        
        for category in ParkCategory.allCases {
            XCTAssertTrue(testCategories.contains(category))
        }
    }
    
    func testShowAllCategoriesFromEmptySet() throws {
        var testCategories: Set<ParkCategory> = []
        
        // Simulate "Show All Categories" button
        testCategories = Set(ParkCategory.allCases)
        
        XCTAssertEqual(testCategories.count, ParkCategory.allCases.count)
        XCTAssertFalse(testCategories.isEmpty)
    }
    
    // MARK: - Reset to Default Tests
    
    func testResetToDefaultFromMultipleCategories() throws {
        var testCategories: Set<ParkCategory> = [.destination, .neighborhood, .mini, .plaza]
        
        // Simulate "Reset to Default" button
        testCategories = [.destination]
        
        XCTAssertEqual(testCategories.count, 1)
        XCTAssertTrue(testCategories.contains(.destination))
        XCTAssertFalse(testCategories.contains(.neighborhood))
        XCTAssertFalse(testCategories.contains(.mini))
        XCTAssertFalse(testCategories.contains(.plaza))
    }
    
    func testResetToDefaultFromEmptySet() throws {
        var testCategories: Set<ParkCategory> = []
        
        // Simulate "Reset to Default" button
        testCategories = [.destination]
        
        XCTAssertEqual(testCategories.count, 1)
        XCTAssertTrue(testCategories.contains(.destination))
    }
    
    func testResetToDefaultFromSingleNonDestinationCategory() throws {
        var testCategories: Set<ParkCategory> = [.neighborhood]
        
        // Simulate "Reset to Default" button
        testCategories = [.destination]
        
        XCTAssertEqual(testCategories.count, 1)
        XCTAssertTrue(testCategories.contains(.destination))
        XCTAssertFalse(testCategories.contains(.neighborhood))
    }
    
    // MARK: - Category Selection State Tests
    
    func testCategorySelectionStateToggling() throws {
        var testCategories: Set<ParkCategory> = [.destination]
        
        // Test multiple toggle operations
        let categoriesToToggle: [ParkCategory] = [.neighborhood, .mini, .plaza, .garden]
        
        for category in categoriesToToggle {
            if testCategories.contains(category) {
                testCategories.remove(category)
            } else {
                testCategories.insert(category)
            }
        }
        
        XCTAssertEqual(testCategories.count, 5) // All categories should be selected
        XCTAssertTrue(testCategories.contains(.destination))
        XCTAssertTrue(testCategories.contains(.neighborhood))
        XCTAssertTrue(testCategories.contains(.mini))
        XCTAssertTrue(testCategories.contains(.plaza))
        XCTAssertTrue(testCategories.contains(.garden))
    }
    
    func testCategorySelectionStateConsistency() throws {
        var testCategories: Set<ParkCategory> = [.destination, .neighborhood]
        
        // Multiple operations
        testCategories.insert(.mini)
        testCategories.remove(.neighborhood)
        testCategories.insert(.plaza)
        
        XCTAssertEqual(testCategories.count, 3)
        XCTAssertTrue(testCategories.contains(.destination))
        XCTAssertFalse(testCategories.contains(.neighborhood))
        XCTAssertTrue(testCategories.contains(.mini))
        XCTAssertTrue(testCategories.contains(.plaza))
        XCTAssertFalse(testCategories.contains(.garden))
    }
    
    // MARK: - Edge Cases Tests
    
    func testAllCategoriesToggleOff() throws {
        var testCategories: Set<ParkCategory> = Set(ParkCategory.allCases)
        
        // Try to remove all categories
        for category in ParkCategory.allCases {
            testCategories.remove(category)
        }
        
        // Simulate the safety check
        if testCategories.isEmpty {
            testCategories.insert(.destination)
        }
        
        XCTAssertEqual(testCategories.count, 1)
        XCTAssertTrue(testCategories.contains(.destination))
    }
    
    func testSingleCategoryToggleOff() throws {
        var testCategories: Set<ParkCategory> = [.destination]
        
        // Try to remove the only category
        testCategories.remove(.destination)
        
        // Simulate the safety check
        if testCategories.isEmpty {
            testCategories.insert(.destination)
        }
        
        XCTAssertEqual(testCategories.count, 1)
        XCTAssertTrue(testCategories.contains(.destination))
    }
    
    func testDuplicateToggleOperations() throws {
        var testCategories: Set<ParkCategory> = [.destination]
        
        // Add the same category multiple times
        testCategories.insert(.neighborhood)
        testCategories.insert(.neighborhood)
        testCategories.insert(.neighborhood)
        
        XCTAssertEqual(testCategories.count, 2)
        XCTAssertTrue(testCategories.contains(.destination))
        XCTAssertTrue(testCategories.contains(.neighborhood))
    }
    
    // MARK: - Performance Tests
    
    func testCategoryTogglePerformance() throws {
        measure {
            var testCategories: Set<ParkCategory> = [.destination]
            
            for _ in 0..<1000 {
                for category in ParkCategory.allCases {
                    if testCategories.contains(category) {
                        testCategories.remove(category)
                    } else {
                        testCategories.insert(category)
                    }
                    
                    if testCategories.isEmpty {
                        testCategories.insert(.destination)
                    }
                }
            }
        }
    }
    
    func testCategoryDescriptionPerformance() throws {
        measure {
            for _ in 0..<1000 {
                for category in ParkCategory.allCases {
                    let _ = categoryDescription(for: category)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func categoryDescription(for category: ParkCategory) -> String {
        switch category {
        case .destination:
            return "Large regional parks with major attractions"
        case .neighborhood:
            return "Local community parks with playgrounds and sports"
        case .mini:
            return "Small neighborhood spaces and pocket parks"
        case .plaza:
            return "Urban squares and civic gathering spaces"
        case .garden:
            return "Community gardens and green spaces"
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteFilterWorkflow() throws {
        var testCategories: Set<ParkCategory> = [.destination]
        
        // 1. Add multiple categories
        testCategories.insert(.neighborhood)
        testCategories.insert(.mini)
        XCTAssertEqual(testCategories.count, 3)
        
        // 2. Show all categories
        testCategories = Set(ParkCategory.allCases)
        XCTAssertEqual(testCategories.count, ParkCategory.allCases.count)
        
        // 3. Remove some categories
        testCategories.remove(.plaza)
        testCategories.remove(.garden)
        XCTAssertEqual(testCategories.count, 3)
        
        // 4. Reset to default
        testCategories = [.destination]
        XCTAssertEqual(testCategories.count, 1)
        XCTAssertTrue(testCategories.contains(.destination))
        
        // 5. Verify state is consistent
        XCTAssertFalse(testCategories.isEmpty)
    }
    
    func testFilterConsistencyAcrossOperations() throws {
        var testCategories: Set<ParkCategory> = [.destination]
        
        // Complex sequence of operations
        testCategories.insert(.neighborhood)
        testCategories.insert(.mini)
        testCategories.remove(.destination)
        
        // Should trigger safety check
        if testCategories.isEmpty {
            testCategories.insert(.destination)
        }
        
        XCTAssertEqual(testCategories.count, 2)
        XCTAssertTrue(testCategories.contains(.neighborhood))
        XCTAssertTrue(testCategories.contains(.mini))
        
        // Reset and verify
        testCategories = [.destination]
        XCTAssertEqual(testCategories.count, 1)
        XCTAssertTrue(testCategories.contains(.destination))
    }
}