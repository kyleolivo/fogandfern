//
//  User.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/20/25.
//

import Foundation
import SwiftData

enum PrivacyLevel: String, CaseIterable, Codable {
    case `private` = "private"
    case friendsOnly = "friends_only"
    case `public` = "public"
    
    var displayName: String {
        switch self {
        case .private: return "Private"
        case .friendsOnly: return "Friends Only"
        case .public: return "Public"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .private: return "lock.fill"
        case .friendsOnly: return "person.2.fill"
        case .public: return "globe"
        }
    }
}

@Model
final class User {
    var id: UUID
    var displayName: String?
    var email: String?
    var createdDate: Date
    var lastActiveDate: Date
    var onboardingCompleted: Bool
    var currentStreakDays: Int
    var longestStreakDays: Int
    var totalParksVisited: Int
    var totalVisits: Int
    var totalJournalEntries: Int
    var preferredUnits: MeasurementSystem
    var defaultPrivacyLevel: PrivacyLevel
    
    // Preferences
    var enableLocationTracking: Bool
    var enableNotifications: Bool
    var enableAnalytics: Bool
    var enableWeatherData: Bool
    var preferredVisitDuration: TimeInterval
    
    // Current city selection
    var currentCityID: UUID?
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Visit.user)
    var visits: [Visit] = []
    
    init(
        id: UUID = UUID(),
        displayName: String? = nil,
        email: String? = nil,
        preferredUnits: MeasurementSystem = .imperial,
        defaultPrivacyLevel: PrivacyLevel = .private,
        enableLocationTracking: Bool = false,
        enableNotifications: Bool = true,
        enableAnalytics: Bool = false,
        enableWeatherData: Bool = true,
        preferredVisitDuration: TimeInterval = 3600, // 1 hour
        currentCityID: UUID? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.preferredUnits = preferredUnits
        self.defaultPrivacyLevel = defaultPrivacyLevel
        self.enableLocationTracking = enableLocationTracking
        self.enableNotifications = enableNotifications
        self.enableAnalytics = enableAnalytics
        self.enableWeatherData = enableWeatherData
        self.preferredVisitDuration = preferredVisitDuration
        self.currentCityID = currentCityID
        self.createdDate = Date()
        self.lastActiveDate = Date()
        self.onboardingCompleted = false
        self.currentStreakDays = 0
        self.longestStreakDays = 0
        self.totalParksVisited = 0
        self.totalVisits = 0
        self.totalJournalEntries = 0
    }
    
    func updateActivity() {
        lastActiveDate = Date()
    }
    
    func completeOnboarding() {
        onboardingCompleted = true
        updateActivity()
    }
    
    var isNewUser: Bool {
        !onboardingCompleted && visits.isEmpty
    }
    
    var averageVisitsPerWeek: Double {
        let daysSinceCreation = Date().timeIntervalSince(createdDate) / (24 * 60 * 60)
        let weeksSinceCreation = max(daysSinceCreation / 7, 1)
        return Double(totalVisits) / weeksSinceCreation
    }
    
    var uniqueParksVisited: Int {
        Set(visits.map(\.park.id)).count
    }
    
    func updateStats() {
        totalVisits = visits.count
        totalParksVisited = uniqueParksVisited
        totalJournalEntries = visits.compactMap(\.journalEntry).filter { !$0.isEmpty }.count
        
        // Update streak calculations
        updateStreakStats()
        
        updateActivity()
    }
    
    private func updateStreakStats() {
        let calendar = Calendar.current
        let sortedVisits = visits.sorted { $0.timestamp < $1.timestamp }
        
        var streak = 0
        var maxStreak = 0
        var lastVisitDate: Date?
        
        for visit in sortedVisits {
            let visitDay = calendar.startOfDay(for: visit.timestamp)
            
            if let lastDate = lastVisitDate {
                let daysBetween = calendar.dateComponents([.day], from: lastDate, to: visitDay).day ?? 0
                
                if daysBetween == 1 {
                    streak += 1
                } else if daysBetween > 1 {
                    maxStreak = max(maxStreak, streak)
                    streak = 1
                }
            } else {
                streak = 1
            }
            
            lastVisitDate = visitDay
        }
        
        maxStreak = max(maxStreak, streak)
        
        // Check if current streak is still active
        if let lastDate = lastVisitDate {
            let daysSinceLastVisit = calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            currentStreakDays = daysSinceLastVisit <= 1 ? streak : 0
        } else {
            currentStreakDays = 0
        }
        
        longestStreakDays = maxStreak
    }
    
}

// MARK: - Measurement System
enum MeasurementSystem: String, CaseIterable, Codable {
    case imperial = "imperial"
    case metric = "metric"
    
    var displayName: String {
        switch self {
        case .imperial: return "Imperial (mi, ft, °F)"
        case .metric: return "Metric (km, m, °C)"
        }
    }
    
    var distanceUnit: String {
        switch self {
        case .imperial: return "mi"
        case .metric: return "km"
        }
    }
    
    var elevationUnit: String {
        switch self {
        case .imperial: return "ft"
        case .metric: return "m"
        }
    }
    
    var temperatureUnit: String {
        switch self {
        case .imperial: return "°F"
        case .metric: return "°C"
        }
    }
}