//
//  ParkDiscoveryView.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/20/25.
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct ParkDiscoveryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Park> { park in park.isActive },
        sort: \Park.name
    ) private var allParks: [Park]
    @Query(sort: \User.createdDate) private var users: [User]
    @Query(sort: \Visit.timestamp, order: .reverse) private var visits: [Visit]
    @State private var locationManager = LocationManager()
    @State private var mapPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7302, longitude: -122.4393),
            span: MKCoordinateSpan(latitudeDelta: 0.17, longitudeDelta: 0.17)
        )
    )
    @State private var selectedPark: Park?
    @State private var selectedCategories: Set<ParkCategory> = [.destination]
    @State private var showingFilterSheet = false
    @State private var showingMapView = true
    
    // Filtered parks based on selected categories
    private var parks: [Park] {
        
        let filtered = allParks.filter { park in
            selectedCategories.contains(park.category)
        }
        
        return filtered
    }
    
    // Parks visible in current map region
    private var visibleParks: [Park] {
        // For now, return all parks since MapCameraPosition doesn't expose region easily
        return parks
    }
    
    // Split parks by visit status for list view
    private var visitedParks: [Park] {
        return parks.filter { hasVisited($0) }.sorted { $0.name < $1.name }
    }
    
    private var unvisitedParks: [Park] {
        parks.filter { !hasVisited($0) }.sorted { $0.name < $1.name }
    }
    
    private func hasVisited(_ park: Park) -> Bool {
        guard let currentUser = getCurrentUser() else { return false }
        let expectedUniqueID = Visit.generateUniqueID(for: park)
        return visits.contains { visit in
            visit.parkUniqueID == expectedUniqueID && visit.user?.id == currentUser.id && visit.isActive
        }
    }
    
    private func markAsVisited(_ park: Park) {
        guard let currentUser = getCurrentUser() else { 
            // Cannot mark as visited: Missing user
            print("⚠️ Cannot mark park '\(park.name)' as visited: Missing user")
            return 
        }
        
        // Marking park as visited
        let expectedUniqueID = Visit.generateUniqueID(for: park)
        
        // Check if park has any visit records (active or inactive)
        let existingVisits = visits.filter { visit in
            visit.parkUniqueID == expectedUniqueID && visit.user?.id == currentUser.id
        }
        
        
        if let existingVisit = existingVisits.first {
            // Toggle the visit status instead of deleting
            existingVisit.isActive.toggle()
            existingVisit.timestamp = Date()  // Update timestamp to track last change
            
            // If there are multiple existing visits, consolidate them
            for additionalVisit in existingVisits.dropFirst() {
                // Delete true duplicates, keeping only the first one
                modelContext.delete(additionalVisit)
            }
        } else {
            // Create new visit using CloudKit-optimized initializer
            let newVisit = Visit(
                timestamp: Date(),
                park: park,
                isActive: true,
                user: currentUser
            )
            modelContext.insert(newVisit)
        }
        
        // Save changes
        do {
            try modelContext.save()
            // Visit data saved successfully
        } catch {
            // Failed to save visit data: \(error)
        }
    }
    
    private func cleanupDuplicateVisits() {
        guard let currentUser = getCurrentUser() else { return }
        
        let userVisits = visits.filter { $0.user?.id == currentUser.id }
        
        // Group visits by park unique ID
        let visitsByPark = Dictionary(grouping: userVisits) { visit in
            visit.parkUniqueID
        }
        
        var duplicatesFound = 0
        var duplicatesRemoved = 0
        
        for (_, parkVisits) in visitsByPark {
            if parkVisits.count > 1 {
                duplicatesFound += parkVisits.count - 1
                
                // Keep the most recent active visit, or if none are active, the most recent inactive
                let sortedVisits = parkVisits.sorted { lhs, rhs in
                    // First sort by active status (active visits first)
                    if lhs.isActive != rhs.isActive {
                        return lhs.isActive && !rhs.isActive
                    }
                    // Then by timestamp (most recent first)
                    return lhs.timestamp > rhs.timestamp
                }
                
                for duplicateVisit in sortedVisits.dropFirst() {
                    modelContext.delete(duplicateVisit)
                    duplicatesRemoved += 1
                }
            }
        }
        
        if duplicatesRemoved > 0 {
            do {
                try modelContext.save()
            } catch {
                print("Failed to save duplicate cleanup: \(error)")
            }
        }
    }
    
    private func selectRandomVisiblePark() {
        guard !visibleParks.isEmpty else { return }
        let randomPark = visibleParks.randomElement()
        selectedPark = randomPark
        
        // Animate map to the selected park's location
        if let park = randomPark {
            withAnimation(.easeInOut(duration: 1.0)) {
                mapPosition = .region(
                    MKCoordinateRegion(
                        center: park.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Full screen map (always rendered but hidden when not in use)
            Map(position: $mapPosition, selection: $selectedPark) {
                ForEach(parks) { park in
                    Marker(park.name, systemImage: "tree.fill", coordinate: park.coordinate)
                        .tint(hasVisited(park) ? .green : .blue)
                        .tag(park)
                }
            }
            .mapStyle(.standard)
            .onShake {
                selectRandomVisiblePark()
            }
            .accessibilityIdentifier("parkMap")
            .accessibilityLabel("Map showing San Francisco parks")
            .opacity(showingMapView ? 1 : 0)
            .allowsHitTesting(showingMapView)
            
            // List view overlay
            if !showingMapView {
                ParkFilteredListView(
                    visitedParks: visitedParks, 
                    unvisitedParks: unvisitedParks,
                    selectedCategories: selectedCategories,
                    onParkSelected: { park in
                        selectedPark = park
                    },
                    onMarkVisited: markAsVisited
                )
                .background(Color(UIColor.systemBackground))
            }
        }
        .sheet(item: $selectedPark) { park in
            ParkDetailOverlay(park: park, onMarkVisited: markAsVisited)
        }
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Picker("View Mode", selection: $showingMapView) {
                    Text("Map").tag(true)
                    Text("List").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 120)
            }
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showingFilterSheet = true
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(selectedCategories.count > 1 ? .blue : .primary)
                }
                .accessibilityIdentifier("filterButton")
                .accessibilityLabel("Settings and park filters")
                
                Button {
                    centerOnUserLocation()
                } label: {
                    Image(systemName: "location")
                        .foregroundColor(.blue)
                }
                .disabled(!locationManager.isLocationAvailable || !showingMapView)
                .accessibilityIdentifier("locationButton")
                .accessibilityLabel("Center map on current location")
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterCategoriesView(selectedCategories: $selectedCategories)
        }
        .onAppear {
            ensureCurrentUserExists()
            locationManager.requestLocationPermission()
            
            // Clean up any duplicate visits on app launch
            cleanupDuplicateVisits()
        }
    }
    
    
    private func centerOnUserLocation() {
        guard let userLocation = locationManager.userLocation else { return }
        
        withAnimation(.easeInOut(duration: 1.0)) {
            mapPosition = .region(
                MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            )
        }
    }
    
    // MARK: - User Management Helper Functions
    
    private func getCurrentUser() -> User? {
        return users.first
    }
    
    private func ensureCurrentUserExists() {
        if users.isEmpty {
            // Creating new user
            let newUser = User()
            modelContext.insert(newUser)
            
            do {
                try modelContext.save()
                // New user created
            } catch {
                // Failed to create user: \(error)
            }
        } else {
            // Using existing user
        }
    }
}

#Preview {
    NavigationStack {
        ParkDiscoveryView()
            .modelContainer(for: [Park.self, City.self], inMemory: true)
    }
}
