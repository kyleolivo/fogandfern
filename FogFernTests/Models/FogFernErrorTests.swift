//
//  FogFernErrorTests.swift
//  FogFernTests
//
//  Created by Claude on 6/29/25.
//

import XCTest
@testable import FogFern

final class FogFernErrorTests: XCTestCase {
    
    // MARK: - ParkRepositoryError Tests
    
    func testParkRepositoryErrorInitialization() throws {
        let testError = ParkRepositoryError(.parkNotFound(id: UUID()), context: ["test": "value"])
        
        XCTAssertNotNil(testError.errorDescription)
        XCTAssertNotNil(testError.failureReason)
        XCTAssertNotNil(testError.recoverySuggestion)
        XCTAssertEqual(testError.context["test"] as? String, "value")
        XCTAssertNil(testError.underlyingError)
    }
    
    func testParkRepositoryErrorWithUnderlyingError() throws {
        let underlyingError = NSError(domain: "TestDomain", code: 123, userInfo: nil)
        let testError = ParkRepositoryError(.networkFailure(reason: "Connection failed"), underlyingError: underlyingError)
        
        XCTAssertNotNil(testError.underlyingError)
        XCTAssertEqual((testError.underlyingError as NSError?)?.code, 123)
    }
    
    func testParkNotFoundError() throws {
        let testID = UUID()
        let error = ParkRepositoryError(.parkNotFound(id: testID))
        
        XCTAssertEqual(error.errorDescription, "Park with ID \(testID) not found")
        XCTAssertEqual(error.failureReason, "The requested park could not be found in the database")
        XCTAssertEqual(error.recoverySuggestion, "Try refreshing the park data or check your internet connection")
    }
    
    func testInvalidParkDataError() throws {
        let reason = "Missing coordinates"
        let error = ParkRepositoryError(.invalidParkData(reason: reason))
        
        XCTAssertEqual(error.errorDescription, "Invalid park data: \(reason)")
        XCTAssertEqual(error.failureReason, "The park data does not meet validation requirements")
        XCTAssertEqual(error.recoverySuggestion, "Please try again or contact support if the problem persists")
    }
    
    func testDuplicateParkError() throws {
        let parkName = "Golden Gate Park"
        let error = ParkRepositoryError(.duplicatePark(name: parkName))
        
        XCTAssertEqual(error.errorDescription, "Park '\(parkName)' already exists")
        XCTAssertEqual(error.failureReason, "A park with this name already exists in the system")
        XCTAssertEqual(error.recoverySuggestion, "Use a different park name or update the existing park")
    }
    
    func testNetworkFailureError() throws {
        let reason = "Timeout after 30 seconds"
        let error = ParkRepositoryError(.networkFailure(reason: reason))
        
        XCTAssertEqual(error.errorDescription, "Network error: \(reason)")
        XCTAssertEqual(error.failureReason, "Unable to connect to the park data service")
        XCTAssertEqual(error.recoverySuggestion, "Check your internet connection and try again")
    }
    
    func testDataCorruptionError() throws {
        let details = "Checksum mismatch"
        let error = ParkRepositoryError(.dataCorruption(details: details))
        
        XCTAssertEqual(error.errorDescription, "Data corruption detected: \(details)")
        XCTAssertEqual(error.failureReason, "The stored park data appears to be corrupted")
        XCTAssertEqual(error.recoverySuggestion, "Try refreshing the app data or reinstalling the app")
    }
    
    func testLocationDataMissingError() throws {
        let error = ParkRepositoryError(.locationDataMissing)
        
        XCTAssertEqual(error.errorDescription, "Location data is missing or invalid")
        XCTAssertEqual(error.failureReason, "Required location information is not available")
        XCTAssertEqual(error.recoverySuggestion, "Enable location services for better park discovery")
    }
    
    func testCityNotSupportedError() throws {
        let cityName = "Seattle"
        let error = ParkRepositoryError(.cityNotSupported(name: cityName))
        
        XCTAssertEqual(error.errorDescription, "City '\(cityName)' is not currently supported")
        XCTAssertEqual(error.failureReason, "This city is not currently supported by Fog & Fern")
        XCTAssertEqual(error.recoverySuggestion, "Check back later as we're expanding to new cities")
    }
    
    // MARK: - UserRepositoryError Tests
    
    func testUserRepositoryErrorInitialization() throws {
        let testError = UserRepositoryError(.authenticationFailed, context: ["method": "oauth"])
        
        XCTAssertNotNil(testError.errorDescription)
        XCTAssertNotNil(testError.recoverySuggestion)
        XCTAssertEqual(testError.context["method"] as? String, "oauth")
        XCTAssertNil(testError.underlyingError)
    }
    
    func testUserRepositoryErrorWithUnderlyingError() throws {
        let underlyingError = NSError(domain: "AuthDomain", code: 401, userInfo: nil)
        let testError = UserRepositoryError(.authenticationFailed, underlyingError: underlyingError)
        
        XCTAssertNotNil(testError.underlyingError)
        XCTAssertEqual((testError.underlyingError as NSError?)?.code, 401)
    }
    
    func testUserNotFoundError() throws {
        let testID = UUID()
        let error = UserRepositoryError(.userNotFound(id: testID))
        
        XCTAssertEqual(error.errorDescription, "User with ID \(testID) not found")
        XCTAssertEqual(error.recoverySuggestion, "Try creating a new user profile")
    }
    
    func testInvalidUserDataError() throws {
        let reason = "Email format invalid"
        let error = UserRepositoryError(.invalidUserData(reason: reason))
        
        XCTAssertEqual(error.errorDescription, "Invalid user data: \(reason)")
        XCTAssertEqual(error.recoverySuggestion, "Please check your input and try again")
    }
    
    func testAuthenticationFailedError() throws {
        let error = UserRepositoryError(.authenticationFailed)
        
        XCTAssertEqual(error.errorDescription, "Authentication failed")
        XCTAssertEqual(error.recoverySuggestion, "Please sign in again")
    }
    
    func testPermissionDeniedError() throws {
        let action = "access photos"
        let error = UserRepositoryError(.permissionDenied(action: action))
        
        XCTAssertEqual(error.errorDescription, "Permission denied for action: \(action)")
        XCTAssertEqual(error.recoverySuggestion, "Enable the required permissions in Settings")
    }
    
    func testProfileIncompleteError() throws {
        let missingFields = ["email", "name"]
        let error = UserRepositoryError(.profileIncomplete(missingFields: missingFields))
        
        XCTAssertEqual(error.errorDescription, "Profile incomplete. Missing: email, name")
        XCTAssertEqual(error.recoverySuggestion, "Complete your profile to continue")
    }
    
    func testProfileIncompleteErrorWithSingleField() throws {
        let missingFields = ["email"]
        let error = UserRepositoryError(.profileIncomplete(missingFields: missingFields))
        
        XCTAssertEqual(error.errorDescription, "Profile incomplete. Missing: email")
        XCTAssertEqual(error.recoverySuggestion, "Complete your profile to continue")
    }
    
    func testProfileIncompleteErrorWithEmptyFields() throws {
        let missingFields: [String] = []
        let error = UserRepositoryError(.profileIncomplete(missingFields: missingFields))
        
        XCTAssertEqual(error.errorDescription, "Profile incomplete. Missing: ")
        XCTAssertEqual(error.recoverySuggestion, "Complete your profile to continue")
    }
    
    // MARK: - Error Context Tests
    
    func testErrorContextHandling() throws {
        let context = [
            "userID": "12345",
            "timestamp": Date(),
            "retryCount": 3,
            "networkStatus": "offline"
        ] as [String: Any]
        
        let error = ParkRepositoryError(.networkFailure(reason: "No connection"), context: context)
        
        XCTAssertEqual(error.context["userID"] as? String, "12345")
        XCTAssertNotNil(error.context["timestamp"] as? Date)
        XCTAssertEqual(error.context["retryCount"] as? Int, 3)
        XCTAssertEqual(error.context["networkStatus"] as? String, "offline")
    }
    
    func testEmptyContext() throws {
        let error = ParkRepositoryError(.locationDataMissing, context: [:])
        XCTAssertTrue(error.context.isEmpty)
    }
    
    // MARK: - Error Chaining Tests
    
    func testErrorChaining() throws {
        let originalError = NSError(domain: "NetworkDomain", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Request timeout"])
        let wrappedError = ParkRepositoryError(.networkFailure(reason: "API timeout"), underlyingError: originalError)
        
        XCTAssertNotNil(wrappedError.underlyingError)
        XCTAssertEqual(wrappedError.errorDescription, "Network error: API timeout")
        
        let nsError = wrappedError.underlyingError as NSError?
        XCTAssertEqual(nsError?.domain, "NetworkDomain")
        XCTAssertEqual(nsError?.code, -1001)
    }
    
    // MARK: - Edge Cases Tests
    
    func testErrorWithSpecialCharacters() throws {
        let specialName = "Park with \"quotes\" & symbols!"
        let error = ParkRepositoryError(.duplicatePark(name: specialName))
        
        XCTAssertEqual(error.errorDescription, "Park '\(specialName)' already exists")
    }
    
    func testErrorWithEmptyStrings() throws {
        let error = ParkRepositoryError(.invalidParkData(reason: ""))
        XCTAssertEqual(error.errorDescription, "Invalid park data: ")
    }
    
    func testErrorWithLongStrings() throws {
        let longReason = String(repeating: "Very long error description. ", count: 100)
        let error = ParkRepositoryError(.invalidParkData(reason: longReason))
        
        XCTAssertTrue(error.errorDescription?.contains(longReason) ?? false)
    }
}