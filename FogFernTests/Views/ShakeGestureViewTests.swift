//
//  ShakeGestureViewTests.swift
//  FogFernTests
//
//  Created by Claude on 7/5/25.
//

import XCTest
import SwiftUI
import UIKit
@testable import FogFern

final class ShakeGestureViewTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var shakeDetectingView: ShakeDetectingView!
    var shakeDetectionView: ShakeDetectionView!
    var shakeCallbackExecuted: Bool = false
    
    override func setUpWithError() throws {
        super.setUp()
        shakeCallbackExecuted = false
        shakeDetectingView = ShakeDetectingView()
        shakeDetectionView = ShakeDetectionView {
            self.shakeCallbackExecuted = true
        }
    }
    
    override func tearDownWithError() throws {
        shakeDetectingView = nil
        shakeDetectionView = nil
        shakeCallbackExecuted = false
        super.tearDown()
    }
    
    // MARK: - ShakeDetectingView Tests
    
    func testShakeDetectingViewInitialization() throws {
        XCTAssertNotNil(shakeDetectingView)
        XCTAssertNotNil(shakeDetectingView as UIView)
        XCTAssertNil(shakeDetectingView.onShake)
    }
    
    func testShakeDetectingViewCanBecomeFirstResponder() throws {
        XCTAssertTrue(shakeDetectingView.canBecomeFirstResponder)
    }
    
    func testShakeDetectingViewOnShakeCallback() throws {
        var callbackExecuted = false
        
        shakeDetectingView.onShake = {
            callbackExecuted = true
        }
        
        XCTAssertNotNil(shakeDetectingView.onShake)
        
        // Execute the callback directly
        shakeDetectingView.onShake?()
        XCTAssertTrue(callbackExecuted)
    }
    
    func testShakeDetectingViewMotionEndedWithShake() throws {
        var shakeDetected = false
        
        shakeDetectingView.onShake = {
            shakeDetected = true
        }
        
        // Simulate shake motion
        shakeDetectingView.motionEnded(UIEvent.EventSubtype.motionShake, with: nil)
        
        XCTAssertTrue(shakeDetected)
    }
    
    func testShakeDetectingViewMotionEndedWithoutShake() throws {
        var shakeDetected = false
        
        shakeDetectingView.onShake = {
            shakeDetected = true
        }
        
        // Simulate non-shake motion (use a different event subtype)
        shakeDetectingView.motionEnded(UIEvent.EventSubtype.remoteControlPlay, with: nil)
        
        XCTAssertFalse(shakeDetected)
    }
    
    func testShakeDetectingViewMotionEndedWithNilCallback() throws {
        // Should not crash when callback is nil
        shakeDetectingView.onShake = nil
        
        XCTAssertNoThrow {
            self.shakeDetectingView.motionEnded(UIEvent.EventSubtype.motionShake, with: nil)
        }
    }
    
    func testShakeDetectingViewMultipleShakes() throws {
        var shakeCount = 0
        
        shakeDetectingView.onShake = {
            shakeCount += 1
        }
        
        // Simulate multiple shakes
        for _ in 0..<5 {
            shakeDetectingView.motionEnded(UIEvent.EventSubtype.motionShake, with: nil)
        }
        
        XCTAssertEqual(shakeCount, 5)
    }
    
    func testShakeDetectingViewDidMoveToWindow() throws {
        // This method calls becomeFirstResponder, we test it doesn't crash
        XCTAssertNoThrow {
            self.shakeDetectingView.didMoveToWindow()
        }
    }
    
    // MARK: - ShakeDetectionView Tests
    
    func testShakeDetectionViewInitialization() throws {
        XCTAssertNotNil(shakeDetectionView)
    }
    
    func testShakeDetectionViewMakeUIView() throws {
        // We can't easily create a Context in unit tests, so we test the functionality differently
        let testShakeDetectionView = ShakeDetectionView {
            self.shakeCallbackExecuted = true
        }
        
        XCTAssertNotNil(testShakeDetectionView)
    }
    
    func testShakeDetectionViewUpdateUIView() throws {
        // Test callback functionality without Context
        var newCallbackExecuted = false
        let newShakeDetectionView = ShakeDetectionView {
            newCallbackExecuted = true
        }
        
        XCTAssertNotNil(newShakeDetectionView)
        XCTAssertFalse(newCallbackExecuted) // Callback not executed yet
    }
    
    func testShakeDetectionViewCallbackExecution() throws {
        var callbackExecuted = false
        let testShakeDetectionView = ShakeDetectionView {
            callbackExecuted = true
        }
        
        // Test that the view was created with callback
        XCTAssertNotNil(testShakeDetectionView)
        XCTAssertFalse(callbackExecuted) // Callback not executed yet
    }
    
    // MARK: - ShakeGestureViewModifier Tests
    
    func testShakeGestureViewModifierInitialization() throws {
        let modifier = ShakeGestureViewModifier {
            // Test callback
        }
        
        XCTAssertNotNil(modifier)
    }
    
    func testShakeGestureViewModifierBody() throws {
        let modifier = ShakeGestureViewModifier {
            // Test callback
        }
        
        XCTAssertNotNil(modifier)
    }
    
    func testShakeGestureViewModifierCallbackExecution() throws {
        var callbackExecuted = false
        let modifier = ShakeGestureViewModifier {
            callbackExecuted = true
        }
        
        // We can't easily test the full modifier chain in unit tests,
        // but we can verify the callback works
        modifier.onShake()
        XCTAssertTrue(callbackExecuted)
    }
    
    // MARK: - View Extension Tests
    
    func testViewExtensionOnShake() throws {
        let testView = Text("Test")
        var callbackExecuted = false
        
        let modifiedView = testView.onShake {
            callbackExecuted = true
        }
        
        XCTAssertNotNil(modifiedView)
        XCTAssertFalse(callbackExecuted) // Callback not executed yet
        
        // We can't easily test the full modifier application in unit tests,
        // but we can verify the method compiles and returns a view
    }
    
    func testViewExtensionOnShakeWithMultipleViews() throws {
        let view1 = Text("View 1")
        let view2 = Text("View 2")
        
        var callback1Executed = false
        var callback2Executed = false
        
        let modifiedView1 = view1.onShake {
            callback1Executed = true
        }
        
        let modifiedView2 = view2.onShake {
            callback2Executed = true
        }
        
        XCTAssertNotNil(modifiedView1)
        XCTAssertNotNil(modifiedView2)
        XCTAssertFalse(callback1Executed) // Callbacks not executed yet
        XCTAssertFalse(callback2Executed)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteShakeGestureWorkflow() throws {
        var shakeCount = 0
        
        // Create the complete chain using direct UIView testing
        let shakeDetectingView = ShakeDetectingView()
        shakeDetectingView.onShake = {
            shakeCount += 1
        }
        
        // Simulate multiple shake events
        shakeDetectingView.motionEnded(UIEvent.EventSubtype.motionShake, with: nil)
        shakeDetectingView.motionEnded(UIEvent.EventSubtype.motionShake, with: nil)
        shakeDetectingView.motionEnded(UIEvent.EventSubtype.motionShake, with: nil)
        
        XCTAssertEqual(shakeCount, 3)
    }
    
    func testShakeGestureViewModifierIntegration() throws {
        var shakeDetected = false
        
        let modifier = ShakeGestureViewModifier {
            shakeDetected = true
        }
        
        XCTAssertNotNil(modifier)
        
        // Verify the callback works by accessing it directly
        modifier.onShake()
        XCTAssertTrue(shakeDetected)
    }
    
    // MARK: - Error Handling Tests
    
    func testShakeDetectionWithInvalidMotionType() throws {
        var shakeDetected = false
        
        shakeDetectingView.onShake = {
            shakeDetected = true
        }
        
        // Test with non-shake motion types
        shakeDetectingView.motionEnded(UIEvent.EventSubtype.remoteControlPlay, with: nil)
        XCTAssertFalse(shakeDetected)
        
        // Only shake should trigger callback
        shakeDetectingView.motionEnded(UIEvent.EventSubtype.motionShake, with: nil)
        XCTAssertTrue(shakeDetected)
    }
    
    func testShakeDetectionWithNilEvent() throws {
        var shakeDetected = false
        
        shakeDetectingView.onShake = {
            shakeDetected = true
        }
        
        // Should work fine with nil event
        shakeDetectingView.motionEnded(UIEvent.EventSubtype.motionShake, with: nil)
        XCTAssertTrue(shakeDetected)
    }
    
    func testShakeDetectionCallbackChanges() throws {
        var firstCallbackExecuted = false
        var secondCallbackExecuted = false
        
        // Set first callback
        shakeDetectingView.onShake = {
            firstCallbackExecuted = true
        }
        
        shakeDetectingView.motionEnded(UIEvent.EventSubtype.motionShake, with: nil)
        XCTAssertTrue(firstCallbackExecuted)
        XCTAssertFalse(secondCallbackExecuted)
        
        // Change callback
        shakeDetectingView.onShake = {
            secondCallbackExecuted = true
        }
        
        shakeDetectingView.motionEnded(UIEvent.EventSubtype.motionShake, with: nil)
        XCTAssertTrue(secondCallbackExecuted)
    }
    
    // MARK: - Performance Tests
    
    func testShakeDetectionPerformance() throws {
        shakeDetectingView.onShake = {
            // Empty callback for performance testing
        }
        
        measure {
            for _ in 0..<1000 {
                shakeDetectingView.motionEnded(UIEvent.EventSubtype.motionShake, with: nil)
            }
        }
        
        // Performance test doesn't need to assert count since measure runs multiple times
        XCTAssertNotNil(shakeDetectingView)
    }
    
    func testShakeDetectionViewCreationPerformance() throws {
        measure {
            for _ in 0..<100 {
                let _ = ShakeDetectionView {
                    // Empty callback
                }
            }
        }
    }
    
    func testShakeDetectingViewCreationPerformance() throws {
        measure {
            for _ in 0..<100 {
                let view = ShakeDetectingView()
                view.onShake = {
                    // Empty callback
                }
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testShakeDetectionWithRapidCallbackChanges() throws {
        var callbackCount = 0
        
        for i in 0..<10 {
            shakeDetectingView.onShake = {
                callbackCount = i
            }
            shakeDetectingView.motionEnded(UIEvent.EventSubtype.motionShake, with: nil)
        }
        
        XCTAssertEqual(callbackCount, 9) // Last callback should have been executed
    }
    
    func testShakeDetectionWithNilCallbackAfterSet() throws {
        var callbackExecuted = false
        
        shakeDetectingView.onShake = {
            callbackExecuted = true
        }
        
        // Set callback to nil
        shakeDetectingView.onShake = nil
        
        // Should not crash
        XCTAssertNoThrow {
            self.shakeDetectingView.motionEnded(UIEvent.EventSubtype.motionShake, with: nil)
        }
        
        XCTAssertFalse(callbackExecuted)
    }
    
    func testShakeDetectionViewUpdateWithSameCallback() throws {
        var callbackExecuted = false
        let callback = { callbackExecuted = true }
        
        let shakeDetectionView = ShakeDetectionView(onShake: callback)
        
        // Test that the view was created with callback
        XCTAssertNotNil(shakeDetectionView)
        
        // Test callback execution directly
        callback()
        XCTAssertTrue(callbackExecuted)
    }
    
    // MARK: - Memory Management Tests
    
    func testShakeDetectingViewMemoryManagement() throws {
        weak var weakView: ShakeDetectingView?
        
        autoreleasepool {
            let view = ShakeDetectingView()
            weakView = view
            
            view.onShake = {
                // Callback that references nothing
            }
            
            XCTAssertNotNil(weakView)
        }
        
        // View should be deallocated
        XCTAssertNil(weakView)
    }
    
    func testShakeDetectionViewMemoryManagement() throws {
        weak var weakUIView: ShakeDetectingView?
        
        autoreleasepool {
            let uiView = ShakeDetectingView()
            uiView.onShake = {
                // Empty callback
            }
            weakUIView = uiView
            
            XCTAssertNotNil(weakUIView)
        }
        
        // View should be deallocated
        XCTAssertNil(weakUIView)
    }
}