//
//  ParkCurationService.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/20/25.
//

import Foundation
import CoreLocation

// MARK: - Park Enhancement Data
struct ParkEnhancement {
    let name: String
    let shortDescription: String
    let fullDescription: String
    let category: ParkCategory
    let bestTimeToVisit: String?
    let accessibilityFeatures: [String]
    let imageURLs: [String]
    let primaryImageURL: String?
    let isFeatured: Bool
    let featuredRank: Int?
}

// MARK: - Park Curation Service
class ParkCurationService {
    static let shared = ParkCurationService()
    
    private init() {}
    
    // MARK: - Public API
    
    func loadCuratedParks(for city: City) async throws -> [Park] {
        guard city.name == "san_francisco" else {
            throw CurationError.unsupportedCity
        }
        
        // Simplified: return empty list since we removed generated enhancement fields
        return []
    }
    
    @MainActor func loadCuratedParksOnMain(for city: City) async throws -> [Park] {
        guard city.name == "san_francisco" else {
            throw CurationError.unsupportedCity
        }
        
        // Simplified: return empty list since we removed generated enhancement fields
        return []
    }
    
    // MARK: - Error Types
    
    enum CurationError: Error, LocalizedError {
        case unsupportedCity
        case dataLoadingFailed
        case invalidPropertyData
        
        var errorDescription: String? {
            switch self {
            case .unsupportedCity:
                return "Curation not available for this city"
            case .dataLoadingFailed:
                return "Failed to load curation data"
            case .invalidPropertyData:
                return "Invalid property data provided"
            }
        }
    }
}