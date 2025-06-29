//
//  Visit.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/20/25.
//

import Foundation
import SwiftData
import CoreLocation

enum MoodRating: Int, CaseIterable, Codable {
    case terrible = 1
    case poor = 2
    case okay = 3
    case good = 4
    case excellent = 5
    
    var displayName: String {
        switch self {
        case .terrible: return "Terrible"
        case .poor: return "Poor"
        case .okay: return "Okay"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }
    
    var emoji: String {
        switch self {
        case .terrible: return "😞"
        case .poor: return "🙁"
        case .okay: return "😐"
        case .good: return "🙂"
        case .excellent: return "😄"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .terrible: return "1.circle.fill"
        case .poor: return "2.circle.fill"
        case .okay: return "3.circle.fill"
        case .good: return "4.circle.fill"
        case .excellent: return "5.circle.fill"
        }
    }
}

enum VisitVerificationStatus: String, CaseIterable, Codable {
    case unverified = "unverified"
    case verified = "verified"
    case approximate = "approximate"
    
    var displayName: String {
        switch self {
        case .unverified: return "Unverified"
        case .verified: return "Verified"
        case .approximate: return "Approximate"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .unverified: return "questionmark.circle"
        case .verified: return "checkmark.circle.fill"
        case .approximate: return "location.circle"
        }
    }
}

@Model
final class Visit {
    var id: UUID
    var timestamp: Date
    var endTime: Date?
    var journalEntry: String?
    var mood: MoodRating?
    var verificationStatus: VisitVerificationStatus
    var isPrivate: Bool
    
    var tags: [String]
    
    // Location verification
    var visitLatitude: Double?
    var visitLongitude: Double?
    var locationAccuracy: Double?
    
    // Weather conditions (optional)
    var weatherDescription: String?
    var temperatureFahrenheit: Double?
    
    // Social aspects
    var companionCount: Int?
    
    var companionNames: [String]
    
    // Activity tracking
    var activitiesCompleted: [String]
    var photosCount: Int
    
    // Metadata
    var createdDate: Date
    var lastModified: Date
    var syncStatus: SyncStatus
    
    // Relationships
    var park: Park
    var user: User
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        endTime: Date? = nil,
        journalEntry: String? = nil,
        mood: MoodRating? = nil,
        verificationStatus: VisitVerificationStatus = .unverified,
        isPrivate: Bool = false,
        tags: [String] = [],
        visitLatitude: Double? = nil,
        visitLongitude: Double? = nil,
        locationAccuracy: Double? = nil,
        weatherDescription: String? = nil,
        temperatureFahrenheit: Double? = nil,
        companionCount: Int? = nil,
        companionNames: [String] = [],
        activitiesCompleted: [String] = [],
        photosCount: Int = 0,
        park: Park,
        user: User
    ) {
        self.id = id
        self.timestamp = timestamp
        self.endTime = endTime
        self.journalEntry = journalEntry
        self.mood = mood
        self.verificationStatus = verificationStatus
        self.isPrivate = isPrivate
        self.tags = tags
        self.visitLatitude = visitLatitude
        self.visitLongitude = visitLongitude
        self.locationAccuracy = locationAccuracy
        self.weatherDescription = weatherDescription
        self.temperatureFahrenheit = temperatureFahrenheit
        self.companionCount = companionCount
        self.companionNames = companionNames
        self.activitiesCompleted = activitiesCompleted
        self.photosCount = photosCount
        self.park = park
        self.user = user
        self.createdDate = Date()
        self.lastModified = Date()
        self.syncStatus = .pending
    }
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(timestamp)
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "In progress" }
        
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(hours)h"
            }
        } else {
            return "\(minutes)m"
        }
    }
    
    var visitCoordinate: CLLocationCoordinate2D? {
        guard let lat = visitLatitude, let lng = visitLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    var visitLocation: CLLocation? {
        guard let coordinate = visitCoordinate else { return nil }
        return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    var isLocationVerified: Bool {
        guard let visitLocation = visitLocation else { return false }
        let distanceFromPark = visitLocation.distance(from: park.location)
        return distanceFromPark <= 100.0 // Within 100 meters
    }
    
    var hasJournalEntry: Bool {
        guard let entry = journalEntry else { return false }
        return !entry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var wordCount: Int {
        guard let entry = journalEntry else { return 0 }
        let words = entry.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
}

// MARK: - Sync Status
enum SyncStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case synced = "synced"
    case failed = "failed"
    case conflict = "conflict"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending Sync"
        case .synced: return "Synced"
        case .failed: return "Sync Failed"
        case .conflict: return "Sync Conflict"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .pending: return "clock.circle"
        case .synced: return "checkmark.icloud"
        case .failed: return "exclamationmark.icloud"
        case .conflict: return "exclamationmark.triangle"
        }
    }
}