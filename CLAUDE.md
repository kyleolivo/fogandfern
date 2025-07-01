# Claude Code Assistant Guide for Fog & Fern

## Project Overview
**Fog & Fern** is a native iOS/macOS SwiftUI application designed to inspire residents and visitors to explore San Francisco's parks and green spaces. The app combines park discovery, visit logging, journaling, and light gamification to encourage outdoor exploration and mindfulness.

**Purpose**: Enable users to discover, visit, log, and reflect on park experiences while building habits through gentle gamification.

**Created**: June 19, 2025  
**Technology Stack**: Swift, SwiftUI, SwiftData, CloudKit  
**Target Platforms**: iOS 18.6+ (iPhone only for MVP)  
**Bundle ID**: `com.kyleolivo.FogFern`  
**Display Name**: "Fog & Fern"  
**App Category**: Healthcare & Fitness  

## Project Structure

```
FogFern/
├── FogFern.xcodeproj/           # Xcode project file
├── FogFern/                     # Main application code
│   ├── FogFern.swift           # App entry point (@main)
│   ├── ContentView.swift          # Primary UI view
│   ├── Item.swift                 # SwiftData model (placeholder)
│   ├── Info.plist                 # App configuration
│   ├── FogFern.entitlements    # App capabilities
│   └── Assets.xcassets/           # App icons and assets
├── FogFernTests/               # Unit tests
├── FogFernUITests/             # UI automation tests
├── Requirements/                  # Product requirements and design
│   ├── Product Requirements.md    # Detailed PRD
│   └── wireframes.png            # UI wireframes
└── README.md                      # Project description
```

## Architecture

### Core Framework Stack
- **SwiftUI**: Declarative UI framework for iOS/macOS
- **SwiftData**: Apple's modern data persistence framework
- **CloudKit**: Cloud synchronization (configured for development)
- **XCTest**: Testing framework for unit and UI tests

### Data Model (Current)
- **Item.swift**: Basic SwiftData model with timestamp (placeholder for park data)
- **ModelContainer**: Configured for persistent storage (not in-memory)
- **Schema**: Currently includes only Item model

### UI Architecture
- **App Entry Point**: `FogFernApp.swift` - Sets up ModelContainer and WindowGroup
- **Main View**: `ContentView.swift` - NavigationSplitView with list/detail layout
- **iPhone-Focused**: Optimized for iPhone for MVP (no iPad/macOS support)
- **Preview Support**: SwiftUI previews with in-memory data for development

### Key Capabilities
- **CloudKit Integration**: Configured for cloud data sync
- **iPhone Only**: MVP focused on iPhone platform
- **App Sandbox**: Enabled for security
- **Background Modes**: Remote notifications supported
- **Previews**: SwiftUI preview system for rapid development

## Development Workflow

### Building & Running
```bash
# Open in Xcode
open FogFern.xcodeproj

# Build for iOS Simulator (iPhone)
xcodebuild -project FogFern.xcodeproj -scheme FogFern -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Build for iPhone Device
xcodebuild -project FogFern.xcodeproj -scheme FogFern -destination 'platform=iOS,name=Any iOS Device' build
```

### Testing
```bash
# Run unit tests
xcodebuild test -project FogFern.xcodeproj -scheme FogFern -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Run UI tests
xcodebuild test -project FogFern.xcodeproj -scheme FogFern -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:FogFernUITests
```

### Code Organization Patterns
- **SwiftUI Views**: Follow declarative UI patterns with `@State`, `@Environment`, `@Query`
- **Data Access**: Use `@Environment(\.modelContext)` for SwiftData operations
- **iPhone-Only**: No platform-specific code needed for MVP
- **Asset Management**: All visual assets in `Assets.xcassets` with proper scaling

## Product Requirements Summary

### Core Features (from PRD)
1. **Park Discovery**: Map-based and list-based park exploration
2. **Visit Logging**: Manual and automatic check-ins with notes
3. **Journaling**: Personal reflection and visit history
4. **Goal Tracking**: Challenges and progress visualization
5. **Badges**: Achievement system for milestones
6. **Profile Dashboard**: Activity summaries and statistics

### Development Phases
- **Phase 0**: ✅ Project setup and scaffolding (COMPLETE)
- **Phase 1**: Park list with hardcoded data
- **Phase 2**: Park detail views and check-in functionality
- **Phase 3**: Visit history and journaling
- **Phase 4**: Profile and static goals
- **Phase 5**: Interactive map integration
- **Phase 6**: Dynamic goal tracking
- **Phase 7**: Visual polish and sharing
- **Phase 8**: User feedback and iteration

### Target Metrics
- D1 Retention: ≥40%
- Average parks visited per user: ≥5 per month
- Visit logging completion: ≥60%
- Goal participation: ≥30%
- Badge unlock rate: ≥50% within 7 days

## Current Implementation Status

### ✅ Completed
- Xcode project setup with multi-platform support
- SwiftData integration with basic Item model
- CloudKit entitlements configuration
- SwiftUI app structure with NavigationSplitView
- Testing targets (unit and UI tests)
- App icon assets (multiple sizes for all platforms)
- Cross-platform build configuration

### 🔄 In Progress / Next Steps
- Replace placeholder Item model with Park data models
- Implement park discovery and listing features
- Add visit logging and check-in functionality
- Create journaling and history views
- Build goal tracking and badge systems

## Key Technical Considerations

### SwiftData Models
- Current: Basic `Item` with timestamp
- Needed: `Park`, `Visit`, `Goal`, `Badge` models
- Use `@Model` macro for SwiftData integration
- Consider relationships between models

### CloudKit Sync
- Development environment configured
- App Groups enabled for data sharing
- Consider offline-first approach with sync

### Cross-Platform Compatibility
- Uses `SDKROOT = auto` for universal builds
- Conditional UI elements for iOS vs macOS
- Shared codebase with platform-specific adaptations

### Location Services (Future)
- Will need location permissions for park proximity
- Consider background location for automatic check-ins
- Privacy-focused implementation required

## Fundamental Coding Principles

### Extensibility & Future-Proofing
**City-Agnostic Design**: While targeting San Francisco initially, the architecture must support easy expansion to other cities:
- Abstract city-specific data (park lists, boundaries, local regulations) into configurable data sources
- Use dependency injection for location-specific services (weather APIs, transit data, local event feeds)
- Design data models to support multiple cities without breaking changes
- Consider city as a first-class entity in the data model from the start

### Code Organization & Composability
**Modular Architecture**: Break functionality into focused, composable modules:
- **Models/**: SwiftData models (`Park`, `Visit`, `Goal`, `Badge`, `City`) in separate files
- **Views/**: SwiftUI views organized by feature area (Discovery, Logging, Profile, etc.)
- **Services/**: Business logic services (`LocationService`, `GoalTrackingService`, `SyncService`)
- **Utilities/**: Reusable components (`DateFormatters`, `LocationHelpers`, `ValidationHelpers`)
- **Extensions/**: Framework extensions grouped by type

**Single Responsibility Principle**: Each file, class, and function should have one clear purpose:
- Avoid monolithic view controllers or service classes
- Extract complex logic into dedicated utility functions
- Keep SwiftUI views focused on presentation, delegate business logic to services
- Use computed properties and small, focused methods

### Testing Strategy
**Test-Driven Development**: Write tests alongside code, not as an afterthought:
- Unit tests for all business logic, models, and utility functions
- SwiftUI view tests using accessibility identifiers and test predicates
- Integration tests for SwiftData operations and CloudKit sync
- UI tests for critical user flows (park discovery, check-ins, goal completion)
- Mock external dependencies (location services, network calls) for reliable testing

### Clean Architecture Patterns
**Separation of Concerns**:
- **Data Layer**: SwiftData models, repositories, and persistence logic
- **Domain Layer**: Business entities, use cases, and core application logic
- **Presentation Layer**: SwiftUI views, view models, and UI state management
- **Infrastructure Layer**: External services, APIs, and framework integrations

**Dependency Direction**: Dependencies should flow inward toward the domain:
- Views depend on view models, not directly on services
- Services depend on protocols, not concrete implementations
- Use Swift protocols for testability and flexibility

### Data Architecture Best Practices
**Robust Data Modeling**:
- Use value types (structs) for immutable data where appropriate
- Implement proper validation at model boundaries
- Design for offline-first functionality with sync capabilities
- Use consistent naming conventions across all data models
- Plan for data migration strategies from the beginning

**State Management**:
- Use `@State` for local view state, `@Environment` for shared app state
- Implement proper error handling and loading states
- Consider using `@Observable` classes for complex shared state
- Avoid massive view state objects; break into focused pieces

### Performance & Scalability Considerations
**Efficient Data Operations**:
- Use SwiftData queries with proper predicates and sorting
- Implement pagination for large datasets (park lists, visit history)
- Cache frequently accessed data appropriately
- Consider memory usage when loading images and media

**SwiftUI Performance**:
- Use `@ViewBuilder` properly to avoid unnecessary view updates  
- Implement efficient list rendering with proper identifiers
- Optimize image loading and caching for park photos
- Profile performance regularly, especially on older devices

### Code Quality Standards
**Maintainability**:
- Use descriptive naming for all functions, variables, and types
- Add inline documentation for complex business logic
- Follow Swift API design guidelines consistently
- Implement proper error handling with meaningful error types
- Use Swift's type system to prevent common bugs (optionals, enums, etc.)

**Code Review Principles**:
- Every feature should be reviewable by focusing on single concerns
- Use meaningful commit messages that explain the "why" not just the "what"
- Keep pull requests focused and reasonably sized
- Document any non-obvious architectural decisions

## Common Development Commands

### Xcode Operations
- **Clean Build Folder**: Cmd+Shift+K
- **Build**: Cmd+B
- **Run**: Cmd+R
- **Test**: Cmd+U
- **Archive**: Product → Archive

### SwiftData Operations
```swift
// Query data
@Query private var items: [Item]

// Insert data
modelContext.insert(newItem)

// Delete data  
modelContext.delete(item)

// Save changes
try modelContext.save()
```

### SwiftUI Previews
```swift
#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
```

## File Locations Reference
- **Project Root**: `/Users/kyleolivo/Developer/FogFern/`
- **Source Code**: `/Users/kyleolivo/Developer/FogFern/FogFern/`
- **Tests**: `/Users/kyleolivo/Developer/FogFern/FogFernTests/`
- **UI Tests**: `/Users/kyleolivo/Developer/FogFern/FogFernUITests/`
- **Requirements**: `/Users/kyleolivo/Developer/FogFern/Requirements/`
- **Project File**: `/Users/kyleolivo/Developer/FogFern/FogFern.xcodeproj/`

---

*This guide should help future Claude Code instances quickly understand the Fog & Fern codebase structure, current implementation status, and development workflow.*
