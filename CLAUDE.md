# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FogFern is a native iOS/macOS SwiftUI application designed to help users discover and explore parks in San Francisco. Built with iOS 18.6+, it uses SwiftData for persistence with CloudKit sync capabilities.

## Commands

### Build Commands
```bash
# Build for iOS Simulator
xcodebuild -scheme FogFern -destination 'platform=iOS Simulator,name=iPhone 16'

# Build for macOS
xcodebuild -scheme FogFern -destination 'platform=macOS'

# Clean build
xcodebuild clean -scheme FogFern
```

### Testing Commands
```bash
# Run all tests with coverage
xcodebuild test -scheme FogFern -destination 'platform=iOS Simulator,name=iPhone 16' -enableCodeCoverage YES -parallel-testing-enabled NO

# Run specific test class
xcodebuild test -scheme FogFern -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:FogFernTests/ParkRepositoryTests -parallel-testing-enabled NO

# Generate coverage report
xcrun xcresulttool get --path <path-to-xcresult> --format json
```

### Linting and Analysis
```bash
# SwiftLint (if installed)
swiftlint

# Static analysis
xcodebuild analyze -scheme FogFern -destination 'platform=iOS Simulator,name=iPhone 16'

# SwiftFormat (if installed)
swiftformat .
```

## Architecture

### Layered Architecture Pattern

1. **Presentation Layer** (`FogFern/Views/`)
   - SwiftUI views with `@Observable` view models
   - Key views: `ContentView`, `ParkListView`, `ParkDetailView`, `ParkDetailSheet`
   - View models handle presentation logic and coordinate with repositories

2. **Domain Layer** (`FogFern/Models/`)
   - SwiftData models: `City`, `Park`, `User`, `Visit`
   - Models include CloudKit sync capabilities
   - Relationships: City → many Parks, User → many Visits → Park

3. **Data Layer** (`FogFern/Repositories/`)
   - Repository pattern for data access
   - `ParkRepository`: Core data operations with category filtering
   - `LocationService`: CLLocationManager wrapper for distance calculations

4. **Infrastructure** (`FogFern/Services/`)
   - `DataLoader`: JSON → SwiftData migration
   - `StoreKitService`: In-app purchases (future)
   - Location services integration

### Key Architectural Decisions

- **Offline-First**: SwiftData provides local persistence with CloudKit sync
- **Observable Pattern**: Modern SwiftUI observation for reactive UI updates
- **Repository Pattern**: Abstracts data access from presentation layer
- **Dependency Injection**: Services injected via SwiftUI environment
- **Multi-City Ready**: Architecture supports expansion beyond San Francisco

### Testing Strategy

- Unit tests for repositories and services
- Integration tests for data persistence
- UI tests for critical user flows
- Test fixtures in `FogFernTests/Fixtures/`

## Development Workflow

1. **Feature Development**
   - Create feature branch from `main`
   - Implement with corresponding tests
   - Use SwiftUI previews for rapid UI development
   - Ensure SwiftData migrations are handled properly

2. **Data Model Changes**
   - Update SwiftData models with proper versioning
   - Test CloudKit sync functionality
   - Update JSON fixtures if needed

3. **UI Development**
   - Use SwiftUI previews extensively
   - Follow Apple's Human Interface Guidelines
   - Test on both iOS and macOS targets

## Important Notes

- The app is designed for iOS 18.6+ to leverage latest SwiftUI features
- CloudKit container: `iCloud.com.apps.fogfern`
- Bundle ID: `com.apps.fogfern`
- Park data is loaded from `parks.json` on first launch
- Distance calculations use CoreLocation for user proximity
- Shake gesture triggers random park discovery
