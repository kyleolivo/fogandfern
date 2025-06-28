//
//  Park.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/20/25.
//

import Foundation
import SwiftData
import CoreLocation

// MARK: - Enums
enum ParkCategory: String, CaseIterable, Codable {
    case destination = "destination"
    case neighborhood = "neighborhood"
    case mini = "mini"
    case plaza = "plaza"
    case garden = "garden"
    case scenic = "scenic"
    case recreational = "recreational"
    case historic = "historic"
    case waterfront = "waterfront"
    
    var displayName: String {
        switch self {
        case .destination: return "Major Parks"
        case .neighborhood: return "Neighborhood Parks"
        case .mini: return "Mini Parks"
        case .plaza: return "Civic Plazas"
        case .garden: return "Community Gardens"
        case .scenic: return "Scenic"
        case .recreational: return "Recreational"
        case .historic: return "Historic"
        case .waterfront: return "Waterfront"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .destination: return "star.fill"
        case .neighborhood: return "house.fill"
        case .mini: return "circle.fill"
        case .plaza: return "building.2.fill"
        case .garden: return "leaf.fill"
        case .scenic: return "mountain.2.fill"
        case .recreational: return "sportscourt.fill"
        case .historic: return "building.columns.fill"
        case .waterfront: return "water.waves"
        }
    }
    
    // Categories included in the main app experience (categories 1-5 from analysis)
    static var mainCategories: [ParkCategory] {
        [.destination, .neighborhood, .mini, .plaza, .garden]
    }
    
    // Helper to check if category should be shown by default
    var isShownByDefault: Bool {
        return self == .destination
    }
}

enum ParkSize: String, CaseIterable, Codable {
    case pocket = "pocket"     // < 1 acre
    case small = "small"       // 1-5 acres
    case medium = "medium"     // 5-20 acres
    case large = "large"       // 20-100 acres
    case massive = "massive"   // 100+ acres
    
    var displayName: String {
        switch self {
        case .pocket: return "Pocket Park"
        case .small: return "Small Park"
        case .medium: return "Medium Park"
        case .large: return "Large Park"
        case .massive: return "Major Park"
        }
    }
    
    static func categorize(acres: Double) -> ParkSize {
        switch acres {
        case 0..<1: return .pocket
        case 1..<5: return .small
        case 5..<20: return .medium
        case 20..<100: return .large
        default: return .massive
        }
    }
}


// MARK: - Park Model
@Model
final class Park {
    var id: UUID
    var name: String
    var officialName: String?
    var shortDescription: String
    var fullDescription: String
    var category: ParkCategory
    var size: ParkSize
    
    // Location
    var latitude: Double
    var longitude: Double
    var address: String
    var neighborhood: String?
    var zipCode: String?
    
    // Physical characteristics
    var acreage: Double
    var squareFeet: Double?
    var elevationFeet: Double?
    
    // Visit information
    var bestTimeToVisit: String?
    
    @Attribute(.transformable(by: NSSecureUnarchiveFromDataTransformer.self))
    var accessibilityFeatures: [String]
    
    // Status and metadata
    var isActive: Bool
    var isFeatured: Bool
    var featuredRank: Int?
    var createdDate: Date
    var lastUpdated: Date
    
    // External data integration
    var sfParksPropertyID: String?
    var sfParksObjectID: Int?
    var lastSyncDate: Date?
    
    // Image management
    @Attribute(.transformable(by: NSSecureUnarchiveFromDataTransformer.self))
    var imageURLs: [String]
    var primaryImageURL: String?
    
    // Relationships
    var city: City
    
    @Relationship(deleteRule: .cascade, inverse: \Visit.park)
    var visits: [Visit] = []
    
    init(
        id: UUID = UUID(),
        name: String,
        officialName: String? = nil,
        shortDescription: String,
        fullDescription: String,
        category: ParkCategory,
        latitude: Double,
        longitude: Double,
        address: String,
        neighborhood: String? = nil,
        zipCode: String? = nil,
        acreage: Double,
        squareFeet: Double? = nil,
        elevationFeet: Double? = nil,
        bestTimeToVisit: String? = nil,
        accessibilityFeatures: [String] = [],
        city: City,
        sfParksPropertyID: String? = nil,
        sfParksObjectID: Int? = nil,
        imageURLs: [String] = [],
        primaryImageURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.officialName = officialName
        self.shortDescription = shortDescription
        self.fullDescription = fullDescription
        self.category = category
        self.size = ParkSize.categorize(acres: acreage)
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.neighborhood = neighborhood
        self.zipCode = zipCode
        self.acreage = acreage
        self.squareFeet = squareFeet
        self.elevationFeet = elevationFeet
        self.bestTimeToVisit = bestTimeToVisit
        self.accessibilityFeatures = accessibilityFeatures
        self.city = city
        self.sfParksPropertyID = sfParksPropertyID
        self.sfParksObjectID = sfParksObjectID
        self.imageURLs = imageURLs
        self.primaryImageURL = primaryImageURL
        self.isActive = true
        self.isFeatured = false
        self.createdDate = Date()
        self.lastUpdated = Date()
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    var formattedAcreage: String {
        if acreage < 1.0 {
            return String(format: "%.1f acres", acreage)
        } else {
            return String(format: "%.0f acres", acreage)
        }
    }
    
    var imageName: String {
        return name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: ".", with: "")
    }
    
}

// MARK: - Distance Calculations
extension Park {
    func distance(from location: CLLocation) -> CLLocationDistance {
        self.location.distance(from: location)
    }
    
    func formattedDistance(from location: CLLocation) -> String {
        let distance = distance(from: location)
        let distanceInMiles = distance * 0.000621371 // Convert meters to miles
        
        if distanceInMiles < 0.1 {
            return "< 0.1 mi"
        } else if distanceInMiles < 1.0 {
            return String(format: "%.1f mi", distanceInMiles)
        } else {
            return String(format: "%.0f mi", distanceInMiles)
        }
    }
}