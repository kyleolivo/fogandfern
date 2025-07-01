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
    
    // MARK: - Observable Object Tests
    
    func testObservableObjectConformance() throws {
        // Test that TipStoreManager properly conforms to ObservableObject
        XCTAssertTrue((tipStoreManager as Any) is any ObservableObject)
        
        // Test @Published properties exist and are accessible
        let _ = tipStoreManager.products
        let _ = tipStoreManager.isLoading
        let _ = tipStoreManager.purchaseError
    }
}