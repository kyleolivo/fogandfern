//
//  SchemaMigrations.swift
//  FogFern
//
//  SwiftData Migration Plans
//  Handles data migration between schema versions
//

import Foundation
import SwiftData

// MARK: - Versioned Migration Plan
struct VersionedMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            _ = try context.fetchCount(FetchDescriptor<SchemaV1.Visit>())
            _ = try context.fetchCount(FetchDescriptor<SchemaV1.User>())
            _ = try context.fetchCount(FetchDescriptor<SchemaV1.Park>())
        },
        didMigrate: { context in
            try context.save()
        }
    )
}

// MARK: - Migration Utilities
struct MigrationUtilities {
    
    // Check if migration is needed
    static func isMigrationNeeded(for container: ModelContainer) -> Bool {
        // SwiftData will automatically determine if migration is needed
        // This is more for logging and debugging purposes
        return true
    }
    
    // Backup data before migration (for critical migrations)
    static func createBackup(context: ModelContext) throws {
        // In a production app, you might want to export critical data
        // to a backup format before major migrations
        
        let visits = try context.fetch(FetchDescriptor<SchemaV1.Visit>())
        _ = try context.fetch(FetchDescriptor<SchemaV1.User>())
        
        UserDefaults.standard.set(visits.count, forKey: "LastBackupVisitCount")
        UserDefaults.standard.set(Date(), forKey: "LastBackupDate")
    }
    
    // Validate data integrity after migration
    static func validateMigration(context: ModelContext) throws -> Bool {
        // Perform sanity checks on migrated data
        
        let visits = try context.fetch(FetchDescriptor<SchemaV1.Visit>())
        let _ = try context.fetch(FetchDescriptor<SchemaV1.User>())
        let parks = try context.fetch(FetchDescriptor<SchemaV1.Park>())
        
        // Basic validation checks
        let hasOrphanedVisits = visits.contains { visit in
            visit.parkUniqueID.isEmpty
        }
        
        _ = parks.contains { park in
            park.sfParksPropertyID?.isEmpty == true
        }
        
        if hasOrphanedVisits {
            return false
        }
        
        return true
    }
}

// MARK: - Migration Error Handling
enum MigrationError: LocalizedError {
    case migrationFailed(reason: String)
    case validationFailed(reason: String)
    case backupFailed(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .migrationFailed(let reason):
            return "Migration failed: \(reason)"
        case .validationFailed(let reason):
            return "Migration validation failed: \(reason)"
        case .backupFailed(let reason):
            return "Backup creation failed: \(reason)"
        }
    }
}