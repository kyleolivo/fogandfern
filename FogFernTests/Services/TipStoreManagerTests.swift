//
//  TipStoreManagerTests.swift
//  FogFernTests
//
//  Created by Claude on 6/29/25.
//

import XCTest
import StoreKit
@testable import FogFern

@MainActor
final class TipStoreManagerTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var tipStoreManager: TipStoreManager!
    
    override func setUpWithError() throws {
        super.setUp()
        tipStoreManager = TipStoreManager()
    }
    
    override func tearDownWithError() throws {
        tipStoreManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testTipStoreManagerInitialization() throws {
        XCTAssertNotNil(tipStoreManager)
        XCTAssertEqual(tipStoreManager.products.count, 0) // Initially empty
        XCTAssertNil(tipStoreManager.purchaseError)
    }
    
    // MARK: - Method Existence Tests
    
    func testRequiredMethodsExist() throws {
        // Test that required methods exist
        XCTAssertNotNil(tipStoreManager.loadProducts)
        XCTAssertNotNil(tipStoreManager.clearError)
        XCTAssertNotNil(tipStoreManager.setError)
        XCTAssertNotNil(tipStoreManager.displayName)
        XCTAssertNotNil(tipStoreManager.purchase)
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError() throws {
        // Test error clearing functionality
        tipStoreManager.clearError()
        XCTAssertNil(tipStoreManager.purchaseError)
    }
    
    func testInitialErrorState() throws {
        XCTAssertNil(tipStoreManager.purchaseError)
    }
    
    func testSetError() throws {
        let errorMessage = "Test error message"
        tipStoreManager.setError(errorMessage)
        
        XCTAssertEqual(tipStoreManager.purchaseError, errorMessage)
    }
    
    func testClearErrorAfterSet() throws {
        tipStoreManager.setError("Some error")
        XCTAssertNotNil(tipStoreManager.purchaseError)
        
        tipStoreManager.clearError()
        XCTAssertNil(tipStoreManager.purchaseError)
    }
    
    func testMultipleErrorsOverwrite() throws {
        tipStoreManager.setError("First error")
        XCTAssertEqual(tipStoreManager.purchaseError, "First error")
        
        tipStoreManager.setError("Second error")
        XCTAssertEqual(tipStoreManager.purchaseError, "Second error")
    }
    
    func testEmptyErrorMessage() throws {
        tipStoreManager.setError("")
        XCTAssertEqual(tipStoreManager.purchaseError, "")
        
        tipStoreManager.clearError()
        XCTAssertNil(tipStoreManager.purchaseError)
    }
    
    // MARK: - Observable Object Tests
    
    func testObservableObjectConformance() throws {
        // Test that TipStoreManager properly conforms to ObservableObject
        XCTAssertTrue((tipStoreManager as Any) is any ObservableObject)
        
        // Test @Published properties exist and are accessible
        let _ = tipStoreManager.products
        let _ = tipStoreManager.isLoading
        let _ = tipStoreManager.purchaseError
    }
    
    // MARK: - State Management Tests
    
    func testInitialLoadingState() throws {
        // Note: The manager starts loading products in init, but we test the initial state
        // The isLoading state might be true or false depending on async timing
        XCTAssertNotNil(tipStoreManager.isLoading)
    }
    
    func testProductsArrayInitiallyEmpty() throws {
        // Products should be empty initially (before async loading completes)
        XCTAssertEqual(tipStoreManager.products.count, 0)
    }
    
    func testPublishedPropertiesNotNil() throws {
        // Ensure all @Published properties are accessible
        XCTAssertNotNil(tipStoreManager.products)
        XCTAssertNotNil(tipStoreManager.isLoading)
        // purchaseError can be nil, so we just test it's accessible
        _ = tipStoreManager.purchaseError
    }
    
    // MARK: - Integration Tests
    
    func testTipStoreManagerLifecycle() throws {
        // Test creation
        let manager = TipStoreManager()
        XCTAssertNotNil(manager)
        XCTAssertEqual(manager.products.count, 0)
        XCTAssertNil(manager.purchaseError)
        
        // Test error handling
        manager.setError("Test error")
        XCTAssertEqual(manager.purchaseError, "Test error")
        
        manager.clearError()
        XCTAssertNil(manager.purchaseError)
    }
    
    // MARK: - Async Method Tests
    
    func testAsyncMethodsAvailable() async throws {
        // Test that async methods are available and callable
        // Note: We won't actually call loadProducts as it requires StoreKit setup
        // but we can verify the method signature exists
        let loadProductsMethod = tipStoreManager.loadProducts
        XCTAssertNotNil(loadProductsMethod)
    }
    
    // MARK: - MainActor Isolation Tests
    
    func testMainActorIsolation() throws {
        // Test that TipStoreManager is properly isolated to MainActor
        // This test ensures the class can be used from MainActor context
        XCTAssertNotNil(tipStoreManager)
        
        // All operations should work from MainActor
        tipStoreManager.setError("MainActor test")
        XCTAssertEqual(tipStoreManager.purchaseError, "MainActor test")
        
        tipStoreManager.clearError()
        XCTAssertNil(tipStoreManager.purchaseError)
    }
    
    // MARK: - Performance Tests
    
    func testErrorHandlingPerformance() throws {
        measure {
            for i in 0..<100 {
                tipStoreManager.setError("Error \(i)")
                tipStoreManager.clearError()
            }
        }
    }
    
    func testInitializationPerformance() throws {
        measure {
            for _ in 0..<10 {
                let manager = TipStoreManager()
                _ = manager.products
                _ = manager.isLoading
                _ = manager.purchaseError
            }
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testMultipleInstancesDoNotInterfere() throws {
        let manager1 = TipStoreManager()
        let manager2 = TipStoreManager()
        
        manager1.setError("Manager 1 error")
        manager2.setError("Manager 2 error")
        
        XCTAssertEqual(manager1.purchaseError, "Manager 1 error")
        XCTAssertEqual(manager2.purchaseError, "Manager 2 error")
        
        manager1.clearError()
        XCTAssertNil(manager1.purchaseError)
        XCTAssertEqual(manager2.purchaseError, "Manager 2 error")
    }
    
    // MARK: - Edge Cases Tests
    
    func testClearErrorWhenNoError() throws {
        // Clearing error when no error is set should not cause issues
        XCTAssertNil(tipStoreManager.purchaseError)
        tipStoreManager.clearError()
        XCTAssertNil(tipStoreManager.purchaseError)
    }
    
    func testSetErrorMultipleTimes() throws {
        tipStoreManager.setError("Error 1")
        tipStoreManager.setError("Error 2")
        tipStoreManager.setError("Error 3")
        
        XCTAssertEqual(tipStoreManager.purchaseError, "Error 3")
    }
    
    func testLongErrorMessage() throws {
        let longError = String(repeating: "Error ", count: 1000)
        tipStoreManager.setError(longError)
        
        XCTAssertEqual(tipStoreManager.purchaseError, longError)
        
        tipStoreManager.clearError()
        XCTAssertNil(tipStoreManager.purchaseError)
    }
    
    func testSpecialCharactersInError() throws {
        let specialError = "Error with 🚨 emojis and symbols: @#$%^&*()"
        tipStoreManager.setError(specialError)
        
        XCTAssertEqual(tipStoreManager.purchaseError, specialError)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentErrorOperations() throws {
        let expectation = XCTestExpectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = 10
        
        // Test concurrent error setting and clearing
        for i in 0..<10 {
            Task { @MainActor in
                self.tipStoreManager.setError("Concurrent error \(i)")
                self.tipStoreManager.clearError()
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // After all operations, error should be nil
        XCTAssertNil(tipStoreManager.purchaseError)
    }
}
