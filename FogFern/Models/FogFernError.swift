//
//  FogFernError.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/28/25.
//

import Foundation

// MARK: - Domain-Specific Error Types

struct ParkRepositoryError: Error, LocalizedError {
    let code: ErrorCode
    let context: [String: Any]
    let underlyingError: Error?
    
    enum ErrorCode {
        case parkNotFound(id: UUID)
        case invalidParkData(reason: String)
        case duplicatePark(name: String)
        case networkFailure(reason: String)
        case dataCorruption(details: String)
        case locationDataMissing
        case cityNotSupported(name: String)
    }
    
    init(_ code: ErrorCode, context: [String: Any] = [:], underlyingError: Error? = nil) {
        self.code = code
        self.context = context
        self.underlyingError = underlyingError
    }
    
    var errorDescription: String? {
        switch code {
        case .parkNotFound(let id):
            return "Park with ID \(id) not found"
        case .invalidParkData(let reason):
            return "Invalid park data: \(reason)"
        case .duplicatePark(let name):
            return "Park '\(name)' already exists"
        case .networkFailure(let reason):
            return "Network error: \(reason)"
        case .dataCorruption(let details):
            return "Data corruption detected: \(details)"
        case .locationDataMissing:
            return "Location data is missing or invalid"
        case .cityNotSupported(let name):
            return "City '\(name)' is not currently supported"
        }
    }
    
    var failureReason: String? {
        switch code {
        case .parkNotFound:
            return "The requested park could not be found in the database"
        case .invalidParkData:
            return "The park data does not meet validation requirements"
        case .duplicatePark:
            return "A park with this name already exists in the system"
        case .networkFailure:
            return "Unable to connect to the park data service"
        case .dataCorruption:
            return "The stored park data appears to be corrupted"
        case .locationDataMissing:
            return "Required location information is not available"
        case .cityNotSupported:
            return "This city is not currently supported by Fog & Fern"
        }
    }
    
    var recoverySuggestion: String? {
        switch code {
        case .parkNotFound:
            return "Try refreshing the park data or check your internet connection"
        case .invalidParkData:
            return "Please try again or contact support if the problem persists"
        case .duplicatePark:
            return "Use a different park name or update the existing park"
        case .networkFailure:
            return "Check your internet connection and try again"
        case .dataCorruption:
            return "Try refreshing the app data or reinstalling the app"
        case .locationDataMissing:
            return "Enable location services for better park discovery"
        case .cityNotSupported:
            return "Check back later as we're expanding to new cities"
        }
    }
}

struct UserRepositoryError: Error, LocalizedError {
    let code: ErrorCode
    let context: [String: Any]
    let underlyingError: Error?
    
    enum ErrorCode {
        case userNotFound(id: UUID)
        case invalidUserData(reason: String)
        case authenticationFailed
        case permissionDenied(action: String)
        case profileIncomplete(missingFields: [String])
    }
    
    init(_ code: ErrorCode, context: [String: Any] = [:], underlyingError: Error? = nil) {
        self.code = code
        self.context = context
        self.underlyingError = underlyingError
    }
    
    var errorDescription: String? {
        switch code {
        case .userNotFound(let id):
            return "User with ID \(id) not found"
        case .invalidUserData(let reason):
            return "Invalid user data: \(reason)"
        case .authenticationFailed:
            return "Authentication failed"
        case .permissionDenied(let action):
            return "Permission denied for action: \(action)"
        case .profileIncomplete(let fields):
            return "Profile incomplete. Missing: \(fields.joined(separator: ", "))"
        }
    }
    
    var recoverySuggestion: String? {
        switch code {
        case .userNotFound:
            return "Try creating a new user profile"
        case .invalidUserData:
            return "Please check your input and try again"
        case .authenticationFailed:
            return "Please sign in again"
        case .permissionDenied:
            return "Enable the required permissions in Settings"
        case .profileIncomplete:
            return "Complete your profile to continue"
        }
    }
}

struct VisitTrackingError: Error, LocalizedError {
    let code: ErrorCode
    let context: [String: Any]
    let underlyingError: Error?
    
    enum ErrorCode {
        case visitNotFound(id: UUID)
        case alreadyVisited(parkName: String)
        case locationVerificationFailed
        case invalidVisitData(reason: String)
        case syncFailure(details: String)
    }
    
    init(_ code: ErrorCode, context: [String: Any] = [:], underlyingError: Error? = nil) {
        self.code = code
        self.context = context
        self.underlyingError = underlyingError
    }
    
    var errorDescription: String? {
        switch code {
        case .visitNotFound(let id):
            return "Visit with ID \(id) not found"
        case .alreadyVisited(let parkName):
            return "You have already visited \(parkName)"
        case .locationVerificationFailed:
            return "Could not verify your location at this park"
        case .invalidVisitData(let reason):
            return "Invalid visit data: \(reason)"
        case .syncFailure(let details):
            return "Failed to sync visit data: \(details)"
        }
    }
    
    var recoverySuggestion: String? {
        switch code {
        case .visitNotFound:
            return "Try refreshing your visit history"
        case .alreadyVisited:
            return "You can update your existing visit or add a journal entry"
        case .locationVerificationFailed:
            return "Make sure you're at the park and location services are enabled"
        case .invalidVisitData:
            return "Please check your input and try again"
        case .syncFailure:
            return "Check your internet connection and try again"
        }
    }
}

struct DataSyncError: Error, LocalizedError {
    let code: ErrorCode
    let context: [String: Any]
    let underlyingError: Error?
    
    enum ErrorCode {
        case cloudKitUnavailable
        case syncConflict(entity: String)
        case quotaExceeded
        case networkTimeout
        case authenticationExpired
    }
    
    init(_ code: ErrorCode, context: [String: Any] = [:], underlyingError: Error? = nil) {
        self.code = code
        self.context = context
        self.underlyingError = underlyingError
    }
    
    var errorDescription: String? {
        switch code {
        case .cloudKitUnavailable:
            return "CloudKit sync is currently unavailable"
        case .syncConflict(let entity):
            return "Sync conflict detected for \(entity)"
        case .quotaExceeded:
            return "iCloud storage quota exceeded"
        case .networkTimeout:
            return "Network request timed out"
        case .authenticationExpired:
            return "Your authentication has expired"
        }
    }
    
    var recoverySuggestion: String? {
        switch code {
        case .cloudKitUnavailable:
            return "Your data is saved locally and will sync when available"
        case .syncConflict:
            return "Please resolve the conflict and try again"
        case .quotaExceeded:
            return "Free up iCloud storage or upgrade your plan"
        case .networkTimeout:
            return "Check your internet connection and try again"
        case .authenticationExpired:
            return "Please sign in to your Apple ID again"
        }
    }
}