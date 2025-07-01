#!/usr/bin/env swift

//
//  GenerateParksData.swift
//  Script to download all SF Parks data and generate comprehensive JSON file
//
//  Run with: swift Scripts/GenerateParksData.swift
//

import Foundation

// Fix for async execution in script
import Dispatch

// MARK: - Data Models (copied from project)

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
    let analysisNeighborhood: String?
    let ownership: String?
    let policeDistrict: String?
}

struct ParkData: Codable {
    let name: String
    let shortDescription: String
    let fullDescription: String
    let category: String
    let latitude: Double
    let longitude: Double
    let address: String
    let neighborhood: String?
    let acreage: Double
    let sfParksObjectID: Int?
    let sfParksPropertyID: String?
}

struct ParksContainer: Codable {
    let version: String
    let parks: [ParkData]
    let generatedDate: String
}

struct ParkDescriptionExport: Codable {
    let name: String
    let neighborhood: String?
    let category: String
    let acreage: Double
    let address: String
    let currentDescription: String
}

struct DescriptionExportContainer: Codable {
    let instructions: String
    let totalParks: Int
    let parks: [ParkDescriptionExport]
    let generatedDate: String
}

struct ParkDescriptionsContainer: Codable {
    let version: String
    let generatedDate: String
    let totalParks: Int
    let descriptions: [String: String]
}


// MARK: - Data Generation

class ParkDataGenerator {
    
    private var enhancedDescriptions: [String: String] = [:]
    
    func generateAllParksData() async throws {
        print("🌲 Fetching all SF Parks data...")
        
        // Load enhanced descriptions
        try loadEnhancedDescriptions()
        
        // Fetch raw data from SF API
        let properties = try await fetchAllProperties()
        print("📊 Found \(properties.count) total park properties")
        
        // Filter and categorize
        let categorizedParks = categorizeParks(properties)
        print("✅ Categorized \(categorizedParks.count) parks into 5 main categories")
        
        // Generate enhanced park data with SF Parks IDs included
        let enhancedParks = categorizedParks.map { property in
            generateParkData(from: property)
        }
        
        // Create category breakdown for logging
        let categoryBreakdown = Dictionary(grouping: enhancedParks, by: { $0.category })
            .mapValues { $0.count }
        
        // Export parks for description generation
        try exportParksForDescriptionGeneration(enhancedParks)
        
        // Create container
        let container = ParksContainer(
            version: "1.0.0",
            parks: enhancedParks.sorted { $0.name < $1.name },
            generatedDate: ISO8601DateFormatter().string(from: Date())
        )
        
        // Save to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let jsonData = try encoder.encode(container)
        
        let outputPath = "../Data/SFParks.json"
        let outputURL = URL(fileURLWithPath: outputPath)
        
        // Create directory if it doesn't exist
        try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), 
                                               withIntermediateDirectories: true)
        
        try jsonData.write(to: outputURL)
        
        print("🎉 Generated comprehensive parks data:")
        print("   📁 Saved to: \(outputPath)")
        print("   📊 Total parks: \(enhancedParks.count)")
        for (category, count) in categoryBreakdown.sorted(by: { $0.key < $1.key }) {
            print("   • \(category): \(count) parks")
        }
    }
    
    private func fetchAllProperties() async throws -> [SFParksProperty] {
        let baseURL = "https://data.sfgov.org/api/views"
        let propertiesDatasetID = "gtr9-ntp6"
        let urlString = "\(baseURL)/\(propertiesDatasetID)/rows.json?max_rows=1000"
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "InvalidURL", code: 0)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Parse SF Open Data format
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[Any]] else {
            throw NSError(domain: "ParseError", code: 0)
        }
        
        return try parsePropertiesFromDataArray(dataArray)
    }
    
    private func parsePropertiesFromDataArray(_ dataArray: [[Any]]) throws -> [SFParksProperty] {
        var properties: [SFParksProperty] = []
        
        for row in dataArray {
            guard row.count >= 30 else { continue }  // Need at least 30 columns for analysis_neighborhood
            
            let property = SFParksProperty(
                objectid: parseInteger(row[8]),
                propertyID: row[9] as? String,
                propertyName: row[10] as? String,
                longitude: parseDouble(row[11]),
                latitude: parseDouble(row[12]),
                acres: parseDouble(row[13]),
                squareFeet: parseDouble(row[14]),
                propertyType: row[16] as? String,
                address: row[17] as? String,
                city: row[18] as? String,
                state: row[19] as? String,
                zipCode: row[20] as? String,
                complex: row[21] as? String,
                analysisNeighborhood: row[24] as? String,
                ownership: row[25] as? String,
                policeDistrict: row[29] as? String
            )
            
            // Only include valid parks with location data
            if let lat = property.latitude, let lon = property.longitude,
               let name = property.propertyName, !name.isEmpty,
               lat > 0, lon < 0 { // Basic SF coordinate validation
                properties.append(property)
            }
        }
        
        return properties
    }
    
    private func parseDouble(_ value: Any?) -> Double? {
        if let doubleValue = value as? Double { return doubleValue }
        if let stringValue = value as? String { return Double(stringValue) }
        if let intValue = value as? Int { return Double(intValue) }
        return nil
    }
    
    private func parseInteger(_ value: Any?) -> Int? {
        if let intValue = value as? Int { return intValue }
        if let stringValue = value as? String { return Int(stringValue) }
        if let doubleValue = value as? Double { return Int(doubleValue) }
        return nil
    }
    
    private func categorizeParks(_ properties: [SFParksProperty]) -> [SFParksProperty] {
        let filteredProperties: [SFParksProperty] = properties.compactMap { property in
            guard let name = property.propertyName?.lowercased(),
                  let type = property.propertyType?.lowercased() else { return nil }
            
            // Exclude libraries, zoos, camp mather (outside SF proper), and other non-park properties
            if type.contains("library") || 
               name.contains("zoo") || 
               name.contains("library") ||
               name.contains("camp mather") ||
               type.contains("concession") ||
               type.contains("camp") { 
                return nil 
            }
            
            let category = determineCategory(from: property)
            return ["destination", "neighborhood", "mini", "plaza", "garden"].contains(category) ? property : nil
        }
        
        // Consolidate Golden Gate Park sections into one entry
        return consolidateGoldenGatePark(filteredProperties)
    }
    
    private func determineCategory(from property: SFParksProperty) -> String {
        let name = property.propertyName?.lowercased() ?? ""
        let type = property.propertyType?.lowercased() ?? ""
        let acres = property.acres ?? 0
        
        // Major Destination Parks (18 parks - crown jewels)
        let majorParks = [
            "golden gate park", "lincoln park", "mclaren park", "presidio",
            "crissy field", "lands end", "twin peaks", "mount davidson",
            "buena vista park", "corona heights park", "glen canyon park"
        ]
        
        for majorPark in majorParks {
            if name.contains(majorPark) { return "destination" }
        }
        
        // Community Gardens (specific type)
        if type.contains("garden") || name.contains("garden") || name.contains("community garden") {
            return "garden"
        }
        
        // Civic Plazas & Urban Squares
        if type.contains("plaza") || type.contains("square") || 
           name.contains("plaza") || name.contains("square") {
            return "plaza"
        }
        
        // Size-based categorization for remaining parks
        if acres >= 20 { return "destination" }  // Large parks
        if acres < 1.0 { return "mini" }        // Pocket parks
        
        return "neighborhood"  // 1-20 acres, the backbone
    }
    
    private func consolidateGoldenGatePark(_ properties: [SFParksProperty]) -> [SFParksProperty] {
        // Find all Golden Gate Park entries
        let goldenGateEntries = properties.filter { property in
            guard let name = property.propertyName?.lowercased() else { return false }
            return name.contains("golden gate park")
        }
        
        // If no Golden Gate Park entries found, return original array
        guard !goldenGateEntries.isEmpty else { return properties }
        
        // Find the best representative entry (prefer one without "section" in name, or largest)
        let mainEntry = goldenGateEntries.first { property in
            guard let name = property.propertyName?.lowercased() else { return false }
            return !name.contains("section")
        } ?? goldenGateEntries.max { (a, b) in
            (a.acres ?? 0) < (b.acres ?? 0)
        }
        
        guard let consolidatedEntry = mainEntry else { return properties }
        
        // Calculate total acreage from all sections
        let totalAcreage = goldenGateEntries.compactMap { $0.acres }.reduce(0, +)
        
        // Create consolidated Golden Gate Park entry
        let consolidatedGoldenGatePark = SFParksProperty(
            objectid: consolidatedEntry.objectid,
            propertyID: consolidatedEntry.propertyID,
            propertyName: "Golden Gate Park",
            longitude: consolidatedEntry.longitude,
            latitude: consolidatedEntry.latitude,
            acres: totalAcreage > 0 ? totalAcreage : consolidatedEntry.acres,
            squareFeet: nil, // Don't combine square feet as it may be inconsistent
            propertyType: consolidatedEntry.propertyType,
            address: consolidatedEntry.address,
            city: consolidatedEntry.city,
            state: consolidatedEntry.state,
            zipCode: consolidatedEntry.zipCode,
            complex: "Golden Gate Park",
            analysisNeighborhood: consolidatedEntry.analysisNeighborhood,
            ownership: consolidatedEntry.ownership,
            policeDistrict: consolidatedEntry.policeDistrict
        )
        
        // Remove all Golden Gate Park entries from the original array
        let propertiesWithoutGoldenGate = properties.filter { property in
            guard let name = property.propertyName?.lowercased() else { return true }
            return !name.contains("golden gate park")
        }
        
        // Add the consolidated entry
        return propertiesWithoutGoldenGate + [consolidatedGoldenGatePark]
    }
    
    private func generateParkData(from property: SFParksProperty) -> ParkData {
        let category = determineCategory(from: property)
        let acres = property.acres ?? 0
        
        return ParkData(
            name: property.propertyName ?? "Unknown Park",
            shortDescription: generateShortDescription(for: property, category: category),
            fullDescription: generateFullDescription(for: property, category: category),
            category: category,
            latitude: property.latitude ?? 37.7749,
            longitude: property.longitude ?? -122.4194,
            address: property.address ?? "San Francisco, CA",
            neighborhood: property.analysisNeighborhood ?? property.complex,
            acreage: acres,
            sfParksObjectID: property.objectid,
            sfParksPropertyID: property.propertyID
        )
    }
    
    private func generateShortDescription(for property: SFParksProperty, category: String) -> String {
        let neighborhood = property.analysisNeighborhood ?? property.complex ?? "San Francisco"
        let acres = property.acres ?? 0
        
        switch category {
        case "destination":
            return "Major \(Int(acres))-acre park with multiple attractions and facilities"
        case "neighborhood":
            return "Community park in \(neighborhood) with recreational facilities"
        case "mini":
            return "Small neighborhood space offering urban respite"
        case "plaza":
            return "Urban plaza and civic gathering space"
        case "garden":
            return "Community garden space for urban agriculture"
        default:
            return "Public park space in \(neighborhood)"
        }
    }
    
    private func exportParksForDescriptionGeneration(_ parks: [ParkData]) throws {
        let exportData = parks.map { park in
            ParkDescriptionExport(
                name: park.name,
                neighborhood: park.neighborhood,
                category: park.category,
                acreage: park.acreage,
                address: park.address,
                currentDescription: park.fullDescription
            )
        }
        
        let instructions = """
        This file contains San Francisco park data for generating enhanced descriptions.
        
        For each park, please create a detailed, engaging description (2-4 sentences) that includes:
        - What makes this park unique or special
        - Key features, amenities, or attractions
        - The park's role in its neighborhood/community
        - Any historical significance or notable characteristics
        
        Consider the park's category, size (acreage), neighborhood context, and location.
        Focus on what visitors would actually experience and enjoy at each park.
        
        Categories:
        - destination: Major parks with significant attractions (20+ acres typically)
        - neighborhood: Community hubs with recreational facilities (1-20 acres)
        - mini: Small urban oases and pocket parks (<1 acre)
        - plaza: Urban squares and civic gathering spaces
        - garden: Community gardens for urban agriculture
        
        Please maintain a consistent, informative yet inspiring tone that would encourage park exploration.
        """
        
        let container = DescriptionExportContainer(
            instructions: instructions,
            totalParks: exportData.count,
            parks: exportData.sorted { $0.name < $1.name },
            generatedDate: ISO8601DateFormatter().string(from: Date())
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let jsonData = try encoder.encode(container)
        
        let exportPath = "../Data/ParksForDescriptionGeneration.json"
        let exportURL = URL(fileURLWithPath: exportPath)
        
        try jsonData.write(to: exportURL)
        
        print("📝 Exported parks for description generation:")
        print("   📁 Saved to: \(exportPath)")
        print("   📊 Ready for LLM processing: \(exportData.count) parks")
    }
    
    
    private func loadEnhancedDescriptions() throws {
        let descriptionsPath = "../Data/ParkDescriptions.json"
        let descriptionsURL = URL(fileURLWithPath: descriptionsPath)
        
        guard FileManager.default.fileExists(atPath: descriptionsURL.path) else {
            print("⚠️  Enhanced descriptions file not found at \(descriptionsPath)")
            print("   Using fallback template descriptions")
            return
        }
        
        let data = try Data(contentsOf: descriptionsURL)
        let container = try JSONDecoder().decode(ParkDescriptionsContainer.self, from: data)
        enhancedDescriptions = container.descriptions
        
        print("📖 Loaded \(enhancedDescriptions.count) enhanced descriptions")
    }
    
    private func generateFullDescription(for property: SFParksProperty, category: String) -> String {
        let name = property.propertyName ?? "this park"
        let neighborhood = property.analysisNeighborhood ?? property.complex ?? "San Francisco"
        
        // First, try to use enhanced description
        if let enhancedDescription = enhancedDescriptions[name] {
            return enhancedDescription
        }
        
        // Fallback to template-based descriptions
        switch category {
        case "destination":
            return "\(name) is a major destination park offering extensive recreational opportunities, multiple attractions, and facilities for visitors to enjoy throughout the day."
        case "neighborhood":
            return "Located in \(neighborhood), \(name) serves as a vital community hub providing recreational facilities, open space, and gathering areas for local residents and families."
        case "mini":
            return "\(name) is a small urban oasis that provides a peaceful respite from city life, offering seating and green space for neighborhood residents and passersby."
        case "plaza":
            return "\(name) is an urban plaza that serves as a civic gathering space, hosting community events and providing a central meeting point in the heart of the city."
        case "garden":
            return "\(name) is a community garden that provides space for urban agriculture, educational programs, and community building around sustainable growing practices."
        default:
            return "\(name) is a public park space that provides recreational opportunities and green space for the community."
        }
    }
    
}

// MARK: - Script Execution

let semaphore = DispatchSemaphore(value: 0)

Task {
    let generator = ParkDataGenerator()
    do {
        try await generator.generateAllParksData()
        print("✅ Script completed successfully")
        semaphore.signal()
    } catch {
        print("❌ Error: \(error)")
        semaphore.signal()
    }
}

semaphore.wait()
exit(0)
