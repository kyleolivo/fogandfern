//
//  UserRepository.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/20/25.
//

import Foundation
import SwiftData

// MARK: - User Repository Protocol
protocol UserRepositoryProtocol {
    func getCurrentUserID() async throws -> PersistentIdentifier
    func createUser(displayName: String?, email: String?) async throws -> PersistentIdentifier
    func updateUser(userID: PersistentIdentifier) async throws
    func updateUserPreferences(userID: PersistentIdentifier, preferences: UserPreferences) async throws
    func updateUserStats(userID: PersistentIdentifier) async throws
    func deleteUser(userID: PersistentIdentifier) async throws
    
    // Main actor methods for UI - reconstruct objects from IDs
    @MainActor func getUser(by id: PersistentIdentifier) throws -> User?
    @MainActor func getCurrentUser() async throws -> User
}

// MARK: - User Preferences
struct UserPreferences {
    let preferredUnits: MeasurementSystem
    let defaultPrivacyLevel: PrivacyLevel
    let enableLocationTracking: Bool
    let enableNotifications: Bool
    let enableAnalytics: Bool
    let enableWeatherData: Bool
    let preferredVisitDuration: TimeInterval
}

// MARK: - User Repository Implementation
class UserRepository: UserRepositoryProtocol {
    private let modelContainer: ModelContainer
    
    private var modelContext: ModelContext {
        ModelContext(modelContainer)
    }
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    // MARK: - Public Methods - Return PersistentIdentifier
    
    func getCurrentUserID() async throws -> PersistentIdentifier {
        let descriptor = FetchDescriptor<User>()
        
        do {
            let users = try modelContext.fetch(descriptor).sorted { $0.createdDate < $1.createdDate }
            
            if let existingUser = users.first {
                existingUser.updateActivity()
                try modelContext.save()
                return existingUser.persistentModelID
            } else {
                // Create default user if none exists
                return try await createUser(displayName: nil, email: nil)
            }
        } catch {
            throw UserRepositoryError(.invalidUserData(reason: "Failed to fetch current user"), underlyingError: error)
        }
    }
    
    func createUser(displayName: String?, email: String?) async throws -> PersistentIdentifier {
        // Validate email if provided
        if let email = email, !email.isEmpty {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            if !emailTest.evaluate(with: email) {
                throw UserRepositoryError(.invalidUserData(reason: "Invalid email format"))
            }
        }
        
        do {
            let user = User(
                displayName: displayName,
                email: email
            )
            
            modelContext.insert(user)
            try modelContext.save()
            
            return user.persistentModelID
        } catch {
            throw UserRepositoryError(.invalidUserData(reason: "Failed to create user"), underlyingError: error)
        }
    }
    
    func updateUser(userID: PersistentIdentifier) async throws {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { user in
                user.persistentModelID == userID
            }
        )
        
        do {
            guard let user = try modelContext.fetch(descriptor).first else {
                throw UserRepositoryError(.userNotFound(id: UUID()))
            }
            user.updateActivity()
            try modelContext.save()
        } catch {
            if error is UserRepositoryError {
                throw error
            } else {
                throw UserRepositoryError(.invalidUserData(reason: "Failed to update user"), underlyingError: error)
            }
        }
    }
    
    func updateUserPreferences(userID: PersistentIdentifier, preferences: UserPreferences) async throws {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { user in
                user.persistentModelID == userID
            }
        )
        
        do {
            guard let user = try modelContext.fetch(descriptor).first else {
                throw UserRepositoryError(.userNotFound(id: UUID()))
            }
            
            user.preferredUnits = preferences.preferredUnits
            user.defaultPrivacyLevel = preferences.defaultPrivacyLevel
            user.enableLocationTracking = preferences.enableLocationTracking
            user.enableNotifications = preferences.enableNotifications
            user.enableAnalytics = preferences.enableAnalytics
            user.enableWeatherData = preferences.enableWeatherData
            user.preferredVisitDuration = preferences.preferredVisitDuration
            
            user.updateActivity()
            try modelContext.save()
        } catch {
            if error is UserRepositoryError {
                throw error
            } else {
                throw UserRepositoryError(.invalidUserData(reason: "Failed to update user preferences"), underlyingError: error)
            }
        }
    }
    
    func updateUserStats(userID: PersistentIdentifier) async throws {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { user in
                user.persistentModelID == userID
            }
        )
        
        do {
            guard let user = try modelContext.fetch(descriptor).first else {
                throw UserRepositoryError(.userNotFound(id: UUID()))
            }
            user.updateStats()
            try modelContext.save()
        } catch {
            if error is UserRepositoryError {
                throw error
            } else {
                throw UserRepositoryError(.invalidUserData(reason: "Failed to update user stats"), underlyingError: error)
            }
        }
    }
    
    func deleteUser(userID: PersistentIdentifier) async throws {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { user in
                user.persistentModelID == userID
            }
        )
        
        do {
            guard let user = try modelContext.fetch(descriptor).first else {
                throw UserRepositoryError(.userNotFound(id: UUID()))
            }
            modelContext.delete(user)
            try modelContext.save()
        } catch {
            if error is UserRepositoryError {
                throw error
            } else {
                throw UserRepositoryError(.invalidUserData(reason: "Failed to delete user"), underlyingError: error)
            }
        }
    }
    
    // MARK: - Main Actor Methods - Reconstruct objects from IDs
    
    @MainActor func getUser(by id: PersistentIdentifier) throws -> User? {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { user in
                user.persistentModelID == id
            }
        )
        
        do {
            return try context.fetch(descriptor).first
        } catch {
            throw UserRepositoryError(.invalidUserData(reason: "Failed to fetch user by ID"), underlyingError: error)
        }
    }
    
    @MainActor func getCurrentUser() async throws -> User {
        do {
            let userID = try await getCurrentUserID()
            guard let user = try getUser(by: userID) else {
                throw UserRepositoryError(.userNotFound(id: UUID()))
            }
            return user
        } catch {
            if error is UserRepositoryError {
                throw error
            } else {
                throw UserRepositoryError(.invalidUserData(reason: "Failed to get current user"), underlyingError: error)
            }
        }
    }
}

// MARK: - User Repository Extensions
extension UserRepository {
    func completeUserOnboarding(userID: PersistentIdentifier, selectedCity: City) async throws {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { user in
                user.persistentModelID == userID
            }
        )
        
        do {
            guard let user = try modelContext.fetch(descriptor).first else {
                throw UserRepositoryError(.userNotFound(id: UUID()))
            }
            
            // Validate that profile is complete
            var missingFields: [String] = []
            if user.displayName?.isEmpty ?? true { missingFields.append("display name") }
            
            if !missingFields.isEmpty {
                throw UserRepositoryError(.profileIncomplete(missingFields: missingFields))
            }
            
            user.completeOnboarding()
            user.currentCityID = selectedCity.id
            try modelContext.save()
        } catch {
            if error is UserRepositoryError {
                throw error
            } else {
                throw UserRepositoryError(.invalidUserData(reason: "Failed to complete user onboarding"), underlyingError: error)
            }
        }
    }
    
    func getUserEngagementMetrics(_ user: User) -> UserEngagementMetrics {
        let totalVisits = user.visits.count
        let uniqueParks = Set(user.visits.map(\.park.id)).count
        let journalEntries = user.visits.compactMap(\.journalEntry).filter { !$0.isEmpty }.count
        let activeGoals = 0
        let completedGoals = 0
        let unlockedBadges = 0
        
        let daysSinceCreation = Date().timeIntervalSince(user.createdDate) / (24 * 60 * 60)
        let averageVisitsPerWeek = daysSinceCreation > 0 ? (Double(totalVisits) / daysSinceCreation) * 7 : 0
        
        return UserEngagementMetrics(
            totalVisits: totalVisits,
            uniqueParks: uniqueParks,
            journalEntries: journalEntries,
            activeGoals: activeGoals,
            completedGoals: completedGoals,
            unlockedBadges: unlockedBadges,
            currentStreak: user.currentStreakDays,
            longestStreak: user.longestStreakDays,
            averageVisitsPerWeek: averageVisitsPerWeek,
            experiencePoints: 0,
            currentLevel: 1
        )
    }
}

// MARK: - Supporting Types
struct UserEngagementMetrics {
    let totalVisits: Int
    let uniqueParks: Int
    let journalEntries: Int
    let activeGoals: Int
    let completedGoals: Int
    let unlockedBadges: Int
    let currentStreak: Int
    let longestStreak: Int
    let averageVisitsPerWeek: Double
    let experiencePoints: Int
    let currentLevel: Int
}

