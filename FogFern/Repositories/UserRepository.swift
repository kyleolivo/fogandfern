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
    func createUser() async throws -> PersistentIdentifier
    func deleteUser(userID: PersistentIdentifier) async throws
    
    // Main actor methods for UI - reconstruct objects from IDs
    @MainActor func getUser(by id: PersistentIdentifier) throws -> User?
    @MainActor func getCurrentUser() async throws -> User
}


// MARK: - User Repository Implementation
class UserRepository: UserRepositoryProtocol {
    private let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    // MARK: - Private Helper Methods
    
    private func findUserInContext(_ user: User, context: ModelContext) throws -> User? {
        let userID = user.id
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { u in u.id == userID }
        )
        let usersInDB = try context.fetch(descriptor)
        return usersInDB.first
    }
    
    // MARK: - Public Methods - Return PersistentIdentifier
    
    func getCurrentUserID() async throws -> PersistentIdentifier {
        let descriptor = FetchDescriptor<User>()
        let context = ModelContext(modelContainer)
        
        do {
            let users = try context.fetch(descriptor).sorted { $0.createdDate < $1.createdDate }
            
            if let existingUser = users.first {
                return existingUser.persistentModelID
            } else {
                // Create default user if none exists
                return try await createUser()
            }
        } catch {
            throw UserRepositoryError(.invalidUserData(reason: "Failed to fetch current user"), underlyingError: error)
        }
    }
    
    func createUser() async throws -> PersistentIdentifier {
        let context = ModelContext(modelContainer)
        do {
            let user = User()
            
            context.insert(user)
            try context.save()
            
            return user.persistentModelID
        } catch {
            throw UserRepositoryError(.invalidUserData(reason: "Failed to create user"), underlyingError: error)
        }
    }
    
    func deleteUser(userID: PersistentIdentifier) async throws {
        let context = ModelContext(modelContainer)
        do {
            let model = context.model(for: userID)
            guard let user = model as? User else {
                throw UserRepositoryError(.userNotFound(id: UUID()))
            }
            context.delete(user)
            try context.save()
        } catch {
            if let error = error as? UserRepositoryError {
                throw error
            }
            throw UserRepositoryError(.userNotFound(id: UUID()))
        }
    }
    
    // MARK: - Main Actor Methods - Reconstruct objects from IDs
    
    @MainActor func getUser(by id: PersistentIdentifier) throws -> User? {
        return try getUserFromContext(by: id, context: modelContainer.mainContext)
    }
    
    // Non-MainActor version for testing
    func getUserForTesting(by id: PersistentIdentifier) throws -> User? {
        let context = ModelContext(modelContainer)
        return try getUserFromContext(by: id, context: context)
    }
    
    private func getUserFromContext(by id: PersistentIdentifier, context: ModelContext) throws -> User? {
        do {
            let model = context.model(for: id)
            guard let user = model as? User else {
                return nil
            }
            // Verify it actually exists in the database
            return try findUserInContext(user, context: context)
        } catch {
            // If the model doesn't exist (was deleted), return nil
            return nil
        }
    }
    
    @MainActor func getCurrentUser() async throws -> User {
        let userID = try await getCurrentUserID()
        guard let user = try getUser(by: userID) else {
            throw UserRepositoryError(.userNotFound(id: UUID()))
        }
        return user
    }
}