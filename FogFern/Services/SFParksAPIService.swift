//
//  SFParksAPIService.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/20/25.
//

import Foundation
import CoreLocation

// MARK: - SF Parks API Response Models
struct SFParksProperty: Codable {
    let objectid: Int?
    let propertyID: String?
    let propertyName: String?
    let longitude: Double?
    let latitude: Double?
    let acres: Double?
    let squareFeet: Double?
    let propertyType: String?
    let address: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let complex: String?
    let ownership: String?
    let policeDistrict: String?
    
    private enum CodingKeys: String, CodingKey {
        case objectid
        case propertyID = "property_id"
        case propertyName = "property_name"
        case longitude
        case latitude
        case acres
        case squareFeet = "squarefeet"
        case propertyType = "propertytype"
        case address
        case city
        case state
        case zipCode = "zipcode"
        case complex
        case ownership
        case policeDistrict = "police_district"
    }
}

struct SFParksFacility: Codable {
    let objectid: Int?
    let facilityName: String?
    let facilityType: String?
    let propertyName: String?
    let longitude: Double?
    let latitude: Double?
    let address: String?
    let squareFeet: Double?
    let acres: Double?
    
    private enum CodingKeys: String, CodingKey {
        case objectid
        case facilityName = "facility_name"
        case facilityType = "facility_type"
        case propertyName = "property_name"
        case longitude
        case latitude
        case address
        case squareFeet = "squarefeet"
        case acres
    }
}

struct SFParksAPIResponse<T: Codable>: Codable {
    let data: [T]
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try container.decode([T].self, forKey: .data)
    }
}

// MARK: - SF Parks API Service
actor SFParksAPIService {
    static let shared = SFParksAPIService()
    
    private let baseURL = "https://data.sfgov.org/api/views"
    private let propertiesDatasetID = "gtr9-ntp6"
    private let facilitiesDatasetID = "ib5c-xgwu"
    
    private let session: URLSession
    private var propertiesCache: [SFParksProperty] = []
    private var facilitiesCache: [SFParksFacility] = []
    private var lastCacheUpdate: Date?
    private let cacheValidityDuration: TimeInterval = 24 * 60 * 60 // 24 hours
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public API
    
    func fetchRegionalParks() async throws -> [SFParksProperty] {
        let allProperties = try await fetchAllProperties()
        return allProperties.filter { property in
            guard let type = property.propertyType else { return false }
            return type.lowercased().contains("regional")
        }
    }
    
    func fetchNeighborhoodParks(minimumAcres: Double = 5.0) async throws -> [SFParksProperty] {
        let allProperties = try await fetchAllProperties()
        return allProperties.filter { property in
            guard let type = property.propertyType,
                  let acres = property.acres else { return false }
            
            let isNeighborhoodPark = type.lowercased().contains("neighborhood")
            let isSizeAppropriate = acres >= minimumAcres
            
            return isNeighborhoodPark && isSizeAppropriate
        }
    }
    
    func fetchCommunityGardens() async throws -> [SFParksProperty] {
        let allProperties = try await fetchAllProperties()
        return allProperties.filter { property in
            guard let type = property.propertyType else { return false }
            return type.lowercased().contains("garden")
        }
    }
    
    func fetchCivicPlazas() async throws -> [SFParksProperty] {
        let allProperties = try await fetchAllProperties()
        return allProperties.filter { property in
            guard let type = property.propertyType else { return false }
            return type.lowercased().contains("plaza") || type.lowercased().contains("square")
        }
    }
    
    func fetchCuratedParks() async throws -> [SFParksProperty] {
        let regionalParks = try await fetchRegionalParks()
        let neighborhoodParks = try await fetchNeighborhoodParks()
        let gardens = try await fetchCommunityGardens()
        let plazas = try await fetchCivicPlazas()
        
        return regionalParks + neighborhoodParks + gardens + plazas
    }
    
    func fetchFacilitiesForPark(propertyName: String) async throws -> [SFParksFacility] {
        let allFacilities = try await fetchAllFacilities()
        return allFacilities.filter { facility in
            guard let facilityParkName = facility.propertyName else { return false }
            return facilityParkName.lowercased() == propertyName.lowercased()
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchAllProperties() async throws -> [SFParksProperty] {
        if let lastUpdate = lastCacheUpdate,
           Date().timeIntervalSince(lastUpdate) < cacheValidityDuration,
           !propertiesCache.isEmpty {
            return propertiesCache
        }
        
        let url = URL(string: "\(baseURL)/\(propertiesDatasetID)/rows.json?max_rows=1000")!
        let data = try await performRequest(url: url)
        
        // Parse the nested JSON structure from SF Open Data
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let dataArray = json["data"] as? [[Any]] {
            
            propertiesCache = try parsePropertiesFromDataArray(dataArray)
            lastCacheUpdate = Date()
            return propertiesCache
        }
        
        throw SFParksAPIError.invalidResponse
    }
    
    private func fetchAllFacilities() async throws -> [SFParksFacility] {
        if let lastUpdate = lastCacheUpdate,
           Date().timeIntervalSince(lastUpdate) < cacheValidityDuration,
           !facilitiesCache.isEmpty {
            return facilitiesCache
        }
        
        let url = URL(string: "\(baseURL)/\(facilitiesDatasetID)/rows.json?max_rows=1000")!
        let data = try await performRequest(url: url)
        
        // Parse the nested JSON structure from SF Open Data
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let dataArray = json["data"] as? [[Any]] {
            
            facilitiesCache = try parseFacilitiesFromDataArray(dataArray)
            return facilitiesCache
        }
        
        throw SFParksAPIError.invalidResponse
    }
    
    private func performRequest(url: URL) async throws -> Data {
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SFParksAPIError.networkError
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw SFParksAPIError.httpError(httpResponse.statusCode)
            }
            
            return data
        } catch {
            if error is SFParksAPIError {
                throw error
            } else {
                throw SFParksAPIError.networkError
            }
        }
    }
    
    private func parsePropertiesFromDataArray(_ dataArray: [[Any]]) throws -> [SFParksProperty] {
        var properties: [SFParksProperty] = []
        
        for row in dataArray {
            guard row.count >= 15 else { continue }
            
            // SF Open Data format: [sid, id, position, created_at, created_meta, updated_at, updated_meta, meta, objectid, property_id, property_name, longitude, latitude, acres, squarefeet, propertytype, address, city, state, zipcode, complex, ownership, police_district]
            
            let property = SFParksProperty(
                objectid: row[8] as? Int,
                propertyID: row[9] as? String,
                propertyName: row[10] as? String,
                longitude: parseDouble(row[11]),
                latitude: parseDouble(row[12]),
                acres: parseDouble(row[13]),
                squareFeet: parseDouble(row[14]),
                propertyType: row[15] as? String,
                address: row[16] as? String,
                city: row[17] as? String,
                state: row[18] as? String,
                zipCode: row[19] as? String,
                complex: row[20] as? String,
                ownership: row[21] as? String,
                policeDistrict: row[22] as? String
            )
            
            // Only include properties with valid location data
            if property.latitude != nil && property.longitude != nil && property.propertyName != nil {
                properties.append(property)
            }
        }
        
        return properties
    }
    
    private func parseFacilitiesFromDataArray(_ dataArray: [[Any]]) throws -> [SFParksFacility] {
        var facilities: [SFParksFacility] = []
        
        for row in dataArray {
            guard row.count >= 10 else { continue }
            
            let facility = SFParksFacility(
                objectid: row[8] as? Int,
                facilityName: row[9] as? String,
                facilityType: row[10] as? String,
                propertyName: row[11] as? String,
                longitude: parseDouble(row[12]),
                latitude: parseDouble(row[13]),
                address: row[14] as? String,
                squareFeet: parseDouble(row[15]),
                acres: parseDouble(row[16])
            )
            
            facilities.append(facility)
        }
        
        return facilities
    }
    
    private func parseDouble(_ value: Any?) -> Double? {
        if let doubleValue = value as? Double {
            return doubleValue
        } else if let stringValue = value as? String {
            return Double(stringValue)
        } else if let intValue = value as? Int {
            return Double(intValue)
        }
        return nil
    }
}

// MARK: - Error Types
enum SFParksAPIError: Error, LocalizedError {
    case networkError
    case invalidResponse
    case httpError(Int)
    case parsingError
    case noDataFound
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection error"
        case .invalidResponse:
            return "Invalid response from SF Parks API"
        case .httpError(let code):
            return "HTTP error \(code)"
        case .parsingError:
            return "Failed to parse SF Parks data"
        case .noDataFound:
            return "No park data found"
        }
    }
}