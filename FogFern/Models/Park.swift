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


@Model
final class Park {
    var id: UUID = UUID()
    var name: String = ""
    var shortDescription: String = ""
    var fullDescription: String = ""
    var category: ParkCategory = ParkCategory.destination
    var size: ParkSize = ParkSize.pocket
    
    // Location - Default to San Francisco coordinates
    var latitude: Double = 37.7749
    var longitude: Double = -122.4194
    var address: String = ""
    var neighborhood: String? = nil
    var zipCode: String? = nil
    
    // Physical characteristics
    var acreage: Double = 0.0
    
    // SF Parks API Integration
    var sfParksPropertyID: String? = nil
    
    // Status and metadata
    var isActive: Bool = true
    var createdDate: Date = Date()
    var lastUpdated: Date = Date()
    
    // Relationships - Optional for CloudKit compatibility
    var city: City? = nil
    
    init(
        id: UUID = UUID(),
        name: String = "",
        shortDescription: String = "",
        fullDescription: String = "",
        category: ParkCategory = ParkCategory.destination,
        latitude: Double = 37.7749,
        longitude: Double = -122.4194,
        address: String = "",
        neighborhood: String? = nil,
        zipCode: String? = nil,
        acreage: Double = 0.0,
        sfParksPropertyID: String? = nil,
        city: City? = nil
    ) {
        self.id = id
        self.name = name
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
        self.sfParksPropertyID = sfParksPropertyID
        self.city = city
        self.isActive = true
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
