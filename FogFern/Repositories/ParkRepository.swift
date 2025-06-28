//
//  ParkRepository.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/20/25.
//

import Foundation
import SwiftData
import CoreLocation

// MARK: - Park Repository Protocol
protocol ParkRepositoryProtocol {
    func getAllParks(for city: City) async throws -> [Park]
    func getFeaturedParks(for city: City) async throws -> [Park]
    func getParksNearLocation(_ location: CLLocation, radius: CLLocationDistance, city: City) async throws -> [Park]
    func getPark(by id: UUID) async throws -> Park?
    func searchParks(query: String, in city: City) async throws -> [Park]
    func getParksBy(category: ParkCategory, in city: City) async throws -> [Park]
    func getParksBy(size: ParkSize, in city: City) async throws -> [Park]
    func syncParksFromRemote(for city: City) async throws -> [Park]
    func refreshParkData(for city: City) async throws
}

// MARK: - Park Repository Implementation
class ParkRepository: ParkRepositoryProtocol {
    private let modelContainer: ModelContainer
    private let curationService = ParkCurationService.shared
    
    private var modelContext: ModelContext {
        ModelContext(modelContainer)
    }
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    // MARK: - Public Methods
    
    func getAllParks(for city: City) async throws -> [Park] {
        let cityId = city.id
        let descriptor = FetchDescriptor<Park>(
            predicate: #Predicate<Park> { park in
                park.city.id == cityId && park.isActive
            }
        )
        
        let parks = try modelContext.fetch(descriptor)
        
        // If no parks found, try to sync from remote
        if parks.isEmpty {
            return try await syncParksFromRemote(for: city)
        }
        
        // Sort manually: featured first, then by featured rank, then by name
        return parks.sorted { lhs, rhs in
            if lhs.isFeatured != rhs.isFeatured {
                return lhs.isFeatured
            } else if lhs.isFeatured && rhs.isFeatured {
                return (lhs.featuredRank ?? 999) < (rhs.featuredRank ?? 999)
            } else {
                return lhs.name < rhs.name
            }
        }
    }
    
    func getFeaturedParks(for city: City) async throws -> [Park] {
        let cityId = city.id
        let descriptor = FetchDescriptor<Park>(
            predicate: #Predicate<Park> { park in
                park.city.id == cityId && park.isActive && park.isFeatured
            }
        )
        
        let parks = try modelContext.fetch(descriptor)
        return parks.sorted { ($0.featuredRank ?? 999) < ($1.featuredRank ?? 999) }
    }
    
    func getParksNearLocation(_ location: CLLocation, radius: CLLocationDistance, city: City) async throws -> [Park] {
        let allParks = try await getAllParks(for: city)
        
        return allParks.filter { park in
            let parkLocation = CLLocation(latitude: park.latitude, longitude: park.longitude)
            return parkLocation.distance(from: location) <= radius
        }.sorted { lhs, rhs in
            let lhsDistance = CLLocation(latitude: lhs.latitude, longitude: lhs.longitude).distance(from: location)
            let rhsDistance = CLLocation(latitude: rhs.latitude, longitude: rhs.longitude).distance(from: location)
            return lhsDistance < rhsDistance
        }
    }
    
    func getPark(by id: UUID) async throws -> Park? {
        let descriptor = FetchDescriptor<Park>(
            predicate: #Predicate<Park> { park in
                park.id == id
            }
        )
        
        let parks = try modelContext.fetch(descriptor)
        return parks.first
    }
    
    func searchParks(query: String, in city: City) async throws -> [Park] {
        let cityId = city.id
        
        let descriptor = FetchDescriptor<Park>(
            predicate: #Predicate<Park> { park in
                park.city.id == cityId && 
                park.isActive && (
                    park.name.localizedStandardContains(query) ||
                    park.shortDescription.localizedStandardContains(query) ||
                    park.neighborhood?.localizedStandardContains(query) == true
                )
            }
        )
        
        let results = try modelContext.fetch(descriptor)
        
        return results.sorted { $0.name < $1.name }
    }
    
    func getParksBy(category: ParkCategory, in city: City) async throws -> [Park] {
        let cityId = city.id
        let descriptor = FetchDescriptor<Park>(
            predicate: #Predicate<Park> { park in
                park.city.id == cityId && park.isActive && park.category == category
            }
        )
        
        let parks = try modelContext.fetch(descriptor)
        return parks.sorted { lhs, rhs in
            if lhs.isFeatured != rhs.isFeatured {
                return lhs.isFeatured
            } else {
                return lhs.name < rhs.name
            }
        }
    }
    
    func getParksBy(size: ParkSize, in city: City) async throws -> [Park] {
        let cityId = city.id
        let descriptor = FetchDescriptor<Park>(
            predicate: #Predicate<Park> { park in
                park.city.id == cityId && park.isActive && park.size == size
            }
        )
        
        let parks = try modelContext.fetch(descriptor)
        return parks.sorted { lhs, rhs in
            if lhs.acreage != rhs.acreage {
                return lhs.acreage > rhs.acreage
            } else {
                return lhs.name < rhs.name
            }
        }
    }
    
    func syncParksFromRemote(for city: City) async throws -> [Park] {
        // Load curated parks from SF Parks API
        let curatedParks = try await curationService.loadCuratedParks(for: city)
        
        // Insert new parks into the database
        for park in curatedParks {
            // Check if park already exists
            let existing = try await getParkBySFParksID(park.sfParksPropertyID, city: city)
            
            if existing == nil {
                modelContext.insert(park)
            } else {
                // Update existing park with new data
                try updateExistingPark(existing!, with: park)
            }
        }
        
        try modelContext.save()
        
        return curatedParks
    }
    
    func refreshParkData(for city: City) async throws {
        _ = try await syncParksFromRemote(for: city)
    }
    
    // MARK: - Main Actor Methods for UI
    
    @MainActor func getAllParksForUI(for city: City) async throws -> [Park] {
        let cityId = city.id
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Park>(
            predicate: #Predicate<Park> { park in
                park.city.id == cityId && park.isActive
            }
        )
        
        let parks = try context.fetch(descriptor)
        
        // If no parks found, try to sync from remote
        if parks.isEmpty {
            return try await syncParksFromRemoteOnMain(for: city)
        }
        
        // Sort manually: featured first, then by featured rank, then by name
        return parks.sorted { lhs, rhs in
            if lhs.isFeatured != rhs.isFeatured {
                return lhs.isFeatured
            } else if lhs.isFeatured && rhs.isFeatured {
                return (lhs.featuredRank ?? 999) < (rhs.featuredRank ?? 999)
            } else {
                return lhs.name < rhs.name
            }
        }
    }
    
    @MainActor private func syncParksFromRemoteOnMain(for city: City) async throws -> [Park] {
        // Load curated parks from SF Parks API
        let curatedParks = try await curationService.loadCuratedParksOnMain(for: city)
        
        let context = modelContainer.mainContext
        
        // Insert new parks into the database
        for park in curatedParks {
            // Check if park already exists
            let existing = try await getParkBySFParksIDOnMain(park.sfParksPropertyID, city: city)
            
            if existing == nil {
                context.insert(park)
            } else {
                // Update existing park with new data
                try updateExistingParkOnMain(existing!, with: park)
            }
        }
        
        try context.save()
        
        return curatedParks
    }
    
    @MainActor private func getParkBySFParksIDOnMain(_ sfParksID: String?, city: City) async throws -> Park? {
        guard let sfParksID = sfParksID else { return nil }
        let cityId = city.id
        let context = modelContainer.mainContext
        
        let descriptor = FetchDescriptor<Park>(
            predicate: #Predicate<Park> { park in
                park.city.id == cityId && park.sfParksPropertyID == sfParksID
            }
        )
        
        let parks = try context.fetch(descriptor)
        return parks.first
    }
    
    @MainActor private func updateExistingParkOnMain(_ existing: Park, with new: Park) throws {
        // Update fields that might have changed
        existing.officialName = new.officialName
        existing.address = new.address
        existing.acreage = new.acreage
        existing.squareFeet = new.squareFeet
        existing.lastUpdated = Date()
        existing.lastSyncDate = Date()
        
        // Don't update enhanced content (descriptions, highlights) to preserve curation
    }
    
    // MARK: - Private Helper Methods
    
    private func getParkBySFParksID(_ sfParksID: String?, city: City) async throws -> Park? {
        guard let sfParksID = sfParksID else { return nil }
        let cityId = city.id
        
        let descriptor = FetchDescriptor<Park>(
            predicate: #Predicate<Park> { park in
                park.city.id == cityId && park.sfParksPropertyID == sfParksID
            }
        )
        
        let parks = try modelContext.fetch(descriptor)
        return parks.first
    }
    
    private func updateExistingPark(_ existing: Park, with new: Park) throws {
        // Update fields that might have changed
        existing.officialName = new.officialName
        existing.address = new.address
        existing.acreage = new.acreage
        existing.squareFeet = new.squareFeet
        existing.lastUpdated = Date()
        existing.lastSyncDate = Date()
        
        // Don't update enhanced content (descriptions, highlights) to preserve curation
    }
}

// MARK: - Repository Extensions for Statistics
extension ParkRepository {
    func getVisitStatistics(for city: City) async throws -> ParkVisitStatistics {
        let allParks = try await getAllParks(for: city)
        let totalParks = allParks.count
        let featuredParks = allParks.filter(\.isFeatured).count
        
        let categoryBreakdown = Dictionary(grouping: allParks, by: \.category)
            .mapValues { $0.count }
        
        let sizeBreakdown = Dictionary(grouping: allParks, by: \.size)
            .mapValues { $0.count }
        
        let totalAcreage = allParks.reduce(0) { $0 + $1.acreage }
        
        return ParkVisitStatistics(
            totalParks: totalParks,
            featuredParks: featuredParks,
            totalAcreage: totalAcreage,
            categoryBreakdown: categoryBreakdown,
            sizeBreakdown: sizeBreakdown
        )
    }
}

// MARK: - Supporting Types
struct ParkVisitStatistics {
    let totalParks: Int
    let featuredParks: Int
    let totalAcreage: Double
    let categoryBreakdown: [ParkCategory: Int]
    let sizeBreakdown: [ParkSize: Int]
}

// MARK: - Repository Error Types
enum RepositoryError: Error, LocalizedError {
    case parkNotFound
    case userNotFound
    case saveFailed
    case syncFailed
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .parkNotFound:
            return "Park not found"
        case .userNotFound:
            return "User not found"
        case .saveFailed:
            return "Failed to save data"
        case .syncFailed:
            return "Failed to sync parks from remote source"
        case .invalidData:
            return "Invalid data"
        }
    }
}