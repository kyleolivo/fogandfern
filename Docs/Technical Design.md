# Fog & Fern Technical Design Document

**Version**: 1.0  
**Date**: June 20, 2025  
**Authors**: Kyle Olivo

## Executive Summary

This document outlines the technical architecture for Fog & Fern, a native iOS/macOS app for exploring San Francisco parks. The design prioritizes multi-city extensibility, offline-first functionality, and a testable code architecture.

**Key Architectural Decisions**:
- Layered architecture with clear separation of concerns
- City-agnostic data models and services from day one
- SwiftData for local persistence with CloudKit sync
- Comprehensive observability and analytics integration
- Test-driven development with extensive mocking capabilities

## Problem Statement & Context

### Current State
- Phase 0 complete: Basic SwiftUI app with SwiftData integration
- Ready to implement Phase 1: Park discovery with hardcoded SF data
- Need architectural foundation before building core features

### Key Challenges
1. **Multi-City Extensibility**: While launching with SF, must support easy expansion to other cities
2. **Offline-First Design**: Users expect functionality without internet connectivity
3. **Complex State Management**: Park visits, goals, badges, and user progress tracking
4. **Performance at Scale**: Efficient data handling as users accumulate visit history
5. **Observability**: Understanding user behavior and app performance in production

## Goals & Non-Goals

### Goals ✅
- **Extensible**: Add new cities without architectural changes
- **Offline-First**: Core functionality works without internet
- **Testable**: Comprehensive unit, integration, and UI test coverage
- **Performant**: Smooth experience on older devices
- **Observable**: Rich analytics and performance monitoring
- **Maintainable**: Clear code organization following Swift best practices

### Non-Goals ❌
- Cross-platform compatibility beyond Apple ecosystem
- Real-time collaboration features
- Complex social networking functionality
- Offline map tile caching (Phase 1)

## Requirements

### Functional Requirements
- **FR1**: Display park lists with filtering and search
- **FR2**: Park detail views with visit logging
- **FR3**: Visit history and journaling
- **FR4**: Goal tracking and badge systems
- **FR5**: User profile and statistics
- **FR6**: CloudKit sync across devices

### Non-Functional Requirements
- **NFR1**: Support iOS 18.6+, macOS 15.5+, visionOS 2.6+
- **NFR2**: Offline functionality for core features
- **NFR3**: 40% D1 retention rate target
- **NFR4**: Sub-2-second app launch time
- **NFR5**: GDPR/CCPA compliant data handling

### Technical Requirements
- **TR0**: We will only support ios 18 and above
- **TR1**: SwiftUI for all user interfaces
- **TR2**: SwiftData for local data persistence
- **TR3**: CloudKit for cross-device synchronization
- **TR4**: Comprehensive crash and performance monitoring

## Architecture Overview

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
├─────────────────────────────────────────────────────────────┤
│  SwiftUI Views          │  View Models   │  Navigation     │
│  - ParkListView         │  - Observable  │  - Router       │
│  - ParkDetailView       │  - @State      │  - DeepLinks    │
│  - ProfileView          │  - @Environment│                 │
└─────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────┐
│                     DOMAIN LAYER                           │
├─────────────────────────────────────────────────────────────┤
│  Use Cases              │  Business Logic │  Validation    │
│  - DiscoverParks        │  - GoalEngine   │  - Rules       │
│  - LogVisit             │  - BadgeSystem  │  - Constraints │
│  - TrackProgress        │  - Analytics    │                │
└─────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────┐
│                      DATA LAYER                            │
├─────────────────────────────────────────────────────────────┤
│  Repositories           │  SwiftData     │  CloudKit Sync  │
│  - ParkRepository       │  - Models      │  - CKContainer  │
│  - VisitRepository      │  - Context     │  - Sync Engine  │
│  - UserRepository       │  - Queries     │  - Conflict Res │
└─────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────┐
│                  INFRASTRUCTURE LAYER                      │
├─────────────────────────────────────────────────────────────┤
│  External Services      │  System APIs   │  Monitoring     │
│  - LocationService      │  - CoreLocation│  - Analytics    │
│  - NotificationService  │  - UserDefaults│  - Crash Report │
│  - CityConfigService    │  - FileSystem  │  - Performance  │
└─────────────────────────────────────────────────────────────┘
```

### Communication Patterns
- **Views → ViewModels**: Binding-based reactive updates
- **ViewModels → Use Cases**: Direct method calls with async/await
- **Use Cases → Repositories**: Protocol-based dependency injection
- **Repositories → Data Sources**: Repository pattern abstraction

## Detailed Component Design

### Data Models

```swift
// Core domain models
@Model
class City {
    var id: UUID
    var name: String
    var displayName: String
    var boundary: CityBoundary
    var timezone: TimeZone
    var configuration: CityConfiguration
    
    // Relationship
    var parks: [Park] = []
}

@Model  
class Park {
    var id: UUID
    var name: String
    var description: String
    var location: CLLocationCoordinate2D
    var address: String
    var amenities: [Amenity]
    var difficulty: DifficultyLevel
    var estimatedVisitDuration: TimeInterval
    var imageURLs: [URL]
    
    // Relationships
    var city: City
    var visits: [Visit] = []
}

@Model
class Visit {
    var id: UUID
    var park: Park
    var user: User
    var timestamp: Date
    var duration: TimeInterval?
    var journalEntry: String?
    var photos: [Data] // Stored as binary data
    var mood: MoodRating?
    var isVerified: Bool = false // For location-based verification
}

@Model
class Goal {
    var id: UUID
    var type: GoalType
    var target: Int
    var progress: Int
    var startDate: Date
    var endDate: Date
    var isCompleted: Bool
    var city: City?
    
    // Relationship
    var user: User
}

@Model
class Badge {
    var id: UUID
    var name: String
    var description: String
    var iconName: String
    var unlockedDate: Date?
    var criteria: BadgeCriteria
    
    // Relationship
    var user: User
}

@Model
class User {
    var id: UUID
    var createdDate: Date
    var preferences: UserPreferences
    var privacySettings: PrivacySettings
    
    // Relationships
    var visits: [Visit] = []
    var goals: [Goal] = []
    var badges: [Badge] = []
}
```

### Service Layer Architecture

```swift
// Location Services
protocol LocationServiceProtocol {
    func requestPermission() async -> LocationPermissionStatus
    func getCurrentLocation() async throws -> CLLocation
    func isUserNearPark(_ park: Park) async throws -> Bool
    func startMonitoringSignificantLocationChanges()
}

// Repository Pattern
protocol ParkRepositoryProtocol {
    func getAllParks(for city: City) async throws -> [Park]
    func getParksNearLocation(_ location: CLLocation, radius: CLLocationDistance) async throws -> [Park]
    func getPark(by id: UUID) async throws -> Park?
    func searchParks(query: String, in city: City) async throws -> [Park]
}

// Goal Tracking
protocol GoalTrackingServiceProtocol {
    func createGoal(_ goal: Goal) async throws
    func updateProgress(for goalId: UUID, increment: Int) async throws
    func checkGoalCompletion(for user: User) async throws -> [Goal]
    func getActiveGoals(for user: User) async throws -> [Goal]
}

// Multi-City Configuration
protocol CityConfigurationServiceProtocol {
    func getAvailableCities() async throws -> [City]
    func loadCityConfiguration(for cityId: UUID) async throws -> CityConfiguration
    func getDefaultCity() async throws -> City
}
```

### View Layer Organization

```
Views/
├── Core/
│   ├── ContentView.swift              // Main navigation container
│   ├── TabView.swift                  // Tab-based navigation
│   └── LaunchView.swift               // Splash/onboarding
├── Discovery/
│   ├── ParkListView.swift             // Main park discovery
│   ├── ParkDetailView.swift           // Individual park details
│   ├── MapView.swift                  // Map-based discovery
│   └── FilterView.swift               // Search and filter UI
├── Logging/
│   ├── CheckInView.swift              // Visit logging interface
│   ├── JournalEntryView.swift         // Visit reflection
│   └── PhotoCaptureView.swift         // Visit photo capture
├── Profile/
│   ├── ProfileView.swift              // User dashboard
│   ├── VisitHistoryView.swift         // Past visits
│   ├── GoalsView.swift                // Goal tracking
│   └── BadgesView.swift               // Achievement display
├── Settings/
│   ├── SettingsView.swift             // App preferences
│   ├── PrivacyView.swift              // Privacy controls
│   └── CitySelectionView.swift        // Multi-city selection
└── Shared/
    ├── Components/                    // Reusable UI components
    ├── Modifiers/                     // Custom view modifiers
    └── Extensions/                    // SwiftUI extensions
```

## Multi-City Extensibility Design

### City Configuration System

```swift
struct CityConfiguration {
    let id: UUID
    let name: String
    let displayName: String
    let boundary: CityBoundary
    let timezone: TimeZone
    let defaultGoals: [GoalTemplate]
    let specialBadges: [BadgeTemplate]
    let localizedStrings: [String: String]
    let externalIntegrations: ExternalIntegrations
}

struct ExternalIntegrations {
    let weatherAPI: WeatherAPIConfig?
    let transitAPI: TransitAPIConfig?
    let eventAPI: EventAPIConfig?
}

// City-specific data loading
class CityDataLoader {
    func loadParkData(for city: City) async throws -> [Park] {
        // Load from JSON, API, or other city-specific source
        switch city.dataSource {
        case .staticJSON(let filename):
            return try await loadFromJSON(filename)
        case .api(let endpoint):
            return try await loadFromAPI(endpoint)
        case .cloudKit(let recordType):
            return try await loadFromCloudKit(recordType)
        }
    }
}
```

### Adding New Cities Process

1. **Create City Configuration**: Add new `CityConfiguration` with boundaries and settings
2. **Provide Park Data**: Add city-specific park data via JSON, API, or CloudKit
3. **Localization**: Add city-specific strings and cultural adaptations
4. **Testing**: City-specific test data and validation
5. **Deployment**: CloudKit schema updates and app release

## Data Architecture

### SwiftData Schema Design

```swift
// Main schema container
extension Schema {
    static let FogFernSchema = Schema([
        City.self,
        Park.self,
        Visit.self,
        Goal.self,
        Badge.self,
        User.self
    ])
}

// Migration handling
extension ModelContainer {
    static func FogFernContainer() throws -> ModelContainer {
        let container = try ModelContainer(
            for: Schema.FogFernSchema,
            configurations: [
                ModelConfiguration(
                    url: URL.applicationSupportDirectory.appending(path: "FogFern.sqlite"),
                    allowsSave: true,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .automatic
                )
            ]
        )
        return container
    }
}
```

### CloudKit Sync Strategy

```swift
// CloudKit record types mapping
extension Park {
    static let cloudKitRecordType = "Park"
    
    var cloudKitRecord: CKRecord {
        let record = CKRecord(recordType: Self.cloudKitRecordType)
        record["name"] = name
        record["description"] = description
        record["location"] = CLLocation(
            latitude: location.latitude,
            longitude: location.longitude
        )
        // ... other fields
        return record
    }
}

// Sync conflict resolution
class CloudKitSyncEngine {
    func resolveConflict<T: Syncable>(_ localRecord: T, _ remoteRecord: T) -> T {
        // Last-write-wins for most fields
        // Special handling for visits (never overwrite)
        // Merge arrays (goals, badges) intelligently
        return remoteRecord.timestamp > localRecord.timestamp ? remoteRecord : localRecord
    }
}
```

### Offline-First Data Flow

```swift
// Repository implements offline-first pattern
class ParkRepository: ParkRepositoryProtocol {
    private let localDataSource: SwiftDataSource
    private let remoteDataSource: CloudKitDataSource
    
    func getAllParks(for city: City) async throws -> [Park] {
        // 1. Return cached data immediately
        let cachedParks = try await localDataSource.getParks(for: city)
        
        // 2. Fetch updates in background
        Task {
            do {
                let remoteParks = try await remoteDataSource.getParks(for: city)
                try await localDataSource.updateParks(remoteParks)
            } catch {
                // Log error but don't fail the user experience
                AnalyticsService.shared.logError(error)
            }
        }
        
        return cachedParks
    }
}
```

## Monitoring & Observability

### Analytics & Usage Tracking

```swift
// Analytics service for user behavior tracking
protocol AnalyticsServiceProtocol {
    func trackEvent(_ event: AnalyticsEvent)
    func trackUserProperty(_ property: UserProperty)
    func trackScreenView(_ screen: ScreenView)
    func setUserId(_ userId: String)
}

// Key events to track
enum AnalyticsEvent {
    case appLaunched
    case parkViewed(parkId: UUID, cityId: UUID)
    case visitLogged(parkId: UUID, duration: TimeInterval?)
    case goalCreated(type: GoalType)
    case goalCompleted(type: GoalType, timeToComplete: TimeInterval)
    case badgeUnlocked(badgeId: UUID)
    case searchPerformed(query: String, resultsCount: Int)
    case cityChanged(from: UUID, to: UUID)
    case journalEntryCreated(wordCount: Int)
    case photoAdded(to: VisitEvent)
    case settingsChanged(setting: SettingType, value: Any)
    case errorOccurred(error: Error, context: String)
}

// User engagement metrics
struct UserEngagementMetrics {
    let sessionDuration: TimeInterval
    let parksViewedPerSession: Int
    let visitsLoggedPerSession: Int
    let averageJournalLength: Int
    let retentionDay1: Bool
    let retentionDay7: Bool
    let retentionDay30: Bool
}
```

### Performance Monitoring

```swift
// Performance tracking service
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    func trackAppLaunchTime() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        DispatchQueue.main.async {
            let launchTime = CFAbsoluteTimeGetCurrent() - startTime
            AnalyticsService.shared.trackEvent(.performanceMetric(.appLaunchTime(launchTime)))
        }
    }
    
    func trackViewLoadTime<T: View>(_ viewType: T.Type, operation: @escaping () async -> Void) {
        Task {
            let startTime = CFAbsoluteTimeGetCurrent()
            await operation()
            let loadTime = CFAbsoluteTimeGetCurrent() - startTime
            
            AnalyticsService.shared.trackEvent(.performanceMetric(.viewLoadTime(
                viewName: String(describing: viewType),
                duration: loadTime
            )))
        }
    }
    
    func trackMemoryUsage() {
        let memoryInfo = mach_task_basic_info()
        let memoryUsage = Double(memoryInfo.resident_size) / 1024.0 / 1024.0 // MB
        
        AnalyticsService.shared.trackEvent(.performanceMetric(.memoryUsage(memoryUsage)))
    }
}

// Key performance metrics
enum PerformanceMetric {
    case appLaunchTime(TimeInterval)
    case viewLoadTime(viewName: String, duration: TimeInterval)
    case databaseQueryTime(queryType: String, duration: TimeInterval)
    case cloudKitSyncTime(operation: String, duration: TimeInterval)
    case imageLoadTime(imageSize: String, duration: TimeInterval)
    case memoryUsage(Double) // MB
    case diskUsage(Double) // MB
    case batteryImpact(BatteryImpactLevel)
}
```

### Stability Monitoring

```swift
// Crash and error reporting
class StabilityMonitor {
    static let shared = StabilityMonitor()
    
    func setupCrashReporting() {
        // Set up crash reporting service (Crashlytics, Bugsnag, etc.)
        NSSetUncaughtExceptionHandler { exception in
            self.logCrash(exception: exception)
        }
    }
    
    func logError(_ error: Error, context: [String: Any] = [:]) {
        let errorInfo = ErrorInfo(
            error: error,
            context: context,
            timestamp: Date(),
            userId: UserDefaults.standard.string(forKey: "userId"),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            deviceInfo: DeviceInfo.current()
        )
        
        // Log to crash reporting service
        CrashReportingService.shared.log(errorInfo)
        
        // Track in analytics
        AnalyticsService.shared.trackEvent(.errorOccurred(error: error, context: context.description))
    }
    
    func trackHealthMetrics() {
        // Monitor app health indicators
        let healthMetrics = AppHealthMetrics(
            crashRate: calculateCrashRate(),
            errorRate: calculateErrorRate(),
            anrRate: calculateANRRate(),
            memoryPressureEvents: getMemoryPressureEvents()
        )
        
        AnalyticsService.shared.trackEvent(.healthMetrics(healthMetrics))
    }
}
```

### Privacy-Compliant Analytics

```swift
// Privacy-first analytics configuration
class PrivacyCompliantAnalytics {
    func configureAnalytics() {
        // Check user consent
        guard UserDefaults.standard.bool(forKey: "analyticsConsent") else {
            // Only track essential error/crash data
            setupEssentialTracking()
            return
        }
        
        // Full analytics with user consent
        setupFullAnalytics()
    }
    
    private func setupEssentialTracking() {
        // Only crash reporting and essential performance metrics
        // No user behavior tracking
        // No personally identifiable information
    }
    
    private func setupFullAnalytics() {
        // Full feature usage analytics
        // Anonymized user behavior patterns
        // Performance and stability metrics
        // A/B testing support
    }
}
```

## Testing Strategy

### Test Architecture

```swift
// Test doubles and mocking
protocol MockLocationService: LocationServiceProtocol {
    var simulatedLocation: CLLocation { get set }
    var simulatedPermissionStatus: LocationPermissionStatus { get set }
}

// Repository mocking for tests
class MockParkRepository: ParkRepositoryProtocol {
    var mockParks: [Park] = []
    var shouldThrowError = false
    
    func getAllParks(for city: City) async throws -> [Park] {
        if shouldThrowError {
            throw MockError.networkFailure
        }
        return mockParks.filter { $0.city.id == city.id }
    }
}

// SwiftUI View Testing
class ParkListViewTests: XCTestCase {
    func testParkListDisplaysCorrectParks() throws {
        let mockParks = MockData.sampleParks
        let mockRepository = MockParkRepository()
        mockRepository.mockParks = mockParks
        
        let view = ParkListView()
            .environment(\.parkRepository, mockRepository)
        
        let host = UIHostingController(rootView: view)
        
        // Test view rendering and data display
        XCTAssertTrue(host.view.contains(text: mockParks[0].name))
    }
}
```

### Test Categories

1. **Unit Tests**: 
   - Business logic (GoalEngine, BadgeSystem)
   - Data model validation
   - Service layer functionality
   - Utility functions

2. **Integration Tests**:
   - SwiftData operations
   - CloudKit sync scenarios
   - Location service integration
   - Multi-city configuration loading

3. **UI Tests**:
   - Critical user flows (park discovery → visit logging)
   - Cross-platform UI behavior
   - Accessibility compliance
   - Performance regression testing

4. **End-to-End Tests**:
   - Complete user journeys
   - Multi-device sync scenarios
   - Offline/online transition handling

## Implementation Phases

### Phase 1: Core Foundation (2-3 weeks)
- [ ] Implement data models (Park, Visit, User, City)
- [ ] Create repository layer with protocols
- [ ] Set up CloudKit sync foundation
- [ ] Implement basic analytics service
- [ ] SF park data integration

### Phase 2: Park Discovery (2-3 weeks)
- [ ] Park list and detail views
- [ ] Search and filtering functionality
- [ ] Location-based park discovery
- [ ] Performance monitoring integration

### Phase 3: Visit Logging (2-3 weeks)
- [ ] Check-in functionality
- [ ] Journal entry system
- [ ] Photo capture and storage
- [ ] Offline-first visit logging

### Phase 4: Goals & Gamification (2-3 weeks)
- [ ] Goal tracking system
- [ ] Badge unlock logic
- [ ] Progress visualization
- [ ] Achievement notifications

### Phase 5: Multi-City Foundation (1-2 weeks)
- [ ] City configuration system
- [ ] Second city implementation (Oakland/Berkeley)
- [ ] City selection UI
- [ ] Cross-city analytics

### Phase 6: Polish & Monitoring (2-3 weeks)
- [ ] Performance optimization
- [ ] Comprehensive crash reporting
- [ ] A/B testing framework
- [ ] Production monitoring dashboard

## Security & Privacy Considerations

### Data Protection
- **Location Data**: Store only necessary precision, implement automatic deletion
- **Photos**: Local storage with user-controlled cloud backup
- **Analytics**: Anonymized user identifiers, no PII collection
- **CloudKit**: End-to-end encryption for sensitive user data

### Privacy Controls
- **Granular Permissions**: Location, camera, notification permissions
- **Data Export**: Full user data export capability
- **Account Deletion**: Complete data removal from all systems
- **Tracking Consent**: Explicit opt-in for behavior analytics

### Security Measures
- **Certificate Pinning**: For any external API calls
- **Keychain Storage**: For sensitive configuration data
- **Code Obfuscation**: For API keys and sensitive constants
- **Jailbreak Detection**: Optional security enhancement

## Risk Assessment & Mitigation

### Technical Risks

| Risk | Impact | Probability | Mitigation |
|------|---------|-------------|------------|
| SwiftData sync conflicts | High | Medium | Implement robust conflict resolution, extensive testing |
| CloudKit quota limits | Medium | Low | Monitor usage, implement graceful degradation |
| Performance on older devices | High | Medium | Regular performance testing, optimization sprints |
| Complex multi-city state management | Medium | Medium | Clear state architecture, comprehensive testing |
| Location permission rejection | High | High | Graceful fallbacks, clear user education |

### Business Risks

| Risk | Impact | Probability | Mitigation |
|------|---------|-------------|------------|
| Low user retention | High | Medium | Comprehensive analytics, rapid iteration |
| Scalability challenges | Medium | Low | Load testing, performance monitoring |
| Privacy regulation changes | Medium | Medium | Privacy-by-design, regular compliance reviews |

## Alternative Approaches Considered

### Core Data vs SwiftData
- **Decision**: SwiftData for modern Swift integration
- **Trade-off**: Less mature but better Swift interop

### Firebase vs CloudKit
- **Decision**: CloudKit for Apple ecosystem integration
- **Trade-off**: Platform-specific but better privacy/performance

### Monolithic vs Modular Architecture
- **Decision**: Modular with clear layer separation
- **Trade-off**: More complex but better maintainability

### Real-time Analytics vs Batch Processing
- **Decision**: Hybrid approach (real-time for crashes, batch for behavior)
- **Trade-off**: Complexity for comprehensive insights

## Open Questions

1. **City Expansion Strategy**: How do we prioritize which cities to add next?
2. **Premium Features**: What functionality might justify a subscription model?
3. **Social Features**: Should we add friend connections or keep it personal?
4. **Gamification Balance**: How much gamification without making it feel artificial?
5. **Accessibility**: What specific accessibility features should we prioritize?
6. **Analytics Vendor**: Which analytics service best balances privacy and insights?

---

**Next Steps**: Review this technical design document, gather feedback, and begin Phase 1 implementation with the core foundation components.
