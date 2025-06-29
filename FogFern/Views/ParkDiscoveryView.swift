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
        allParks.filter { park in
            selectedCategories.contains(park.category)
        }
    }
    
    // Parks visible in current map region
    private var visibleParks: [Park] {
        // For now, return all parks since MapCameraPosition doesn't expose region easily
        return parks
    }
    
    // Split parks by visit status for list view
    private var visitedParks: [Park] {
        parks.filter { hasVisited($0) }.sorted { $0.name < $1.name }
    }
    
    private var unvisitedParks: [Park] {
        parks.filter { !hasVisited($0) }.sorted { $0.name < $1.name }
    }
    
    private func hasVisited(_ park: Park) -> Bool {
        guard let currentUser = getCurrentUser() else { return false }
        return visits.contains { visit in
            visit.park.id == park.id && visit.user.id == currentUser.id
        }
    }
    
    private func markAsVisited(_ park: Park) {
        guard let currentUser = getCurrentUser() else { return }
        
        // Check if park is already visited
        if let existingVisit = visits.first(where: { visit in
            visit.park.id == park.id && visit.user.id == currentUser.id
        }) {
            // Remove the visit (unmark as visited)
            modelContext.delete(existingVisit)
        } else {
            // Create new visit
            let newVisit = Visit(
                timestamp: Date(),
                park: park,
                user: currentUser
            )
            modelContext.insert(newVisit)
        }
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            // TODO: Implement proper error handling with user notification
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
        Group {
            if showingMapView {
                // Full screen map
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
            } else {
                // List view
                ParkFilteredListView(
                    visitedParks: visitedParks, 
                    unvisitedParks: unvisitedParks,
                    selectedCategories: selectedCategories,
                    onParkSelected: { park in
                        selectedPark = park
                    },
                    onMarkVisited: markAsVisited
                )
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
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(selectedCategories.count > 1 ? .blue : .primary)
                }
                
                Button {
                    centerOnUserLocation()
                } label: {
                    Image(systemName: "location")
                        .foregroundColor(.blue)
                }
                .disabled(!locationManager.isLocationAvailable || !showingMapView)
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterCategoriesView(selectedCategories: $selectedCategories)
        }
        .onAppear {
            loadParks()
            ensureCurrentUserExists()
            locationManager.requestLocationPermission()
        }
    }
    
    @State private var hasLoadedParks = false
    
    private func loadParks() {
        // Only load parks once during the app session
        guard !hasLoadedParks else {
            return
        }
        
        hasLoadedParks = true
        
        do {
            // ParkDataLoader will create its own city instance
            try ParkDataLoader.loadParks(into: modelContext, for: City.sanFrancisco)
        } catch {
            hasLoadedParks = false // Reset so we can try again
            try? modelContext.save()
            // TODO: Implement proper error handling with user notification
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
            let newUser = User()
            modelContext.insert(newUser)
            
            do {
                try modelContext.save()
            } catch {
                // TODO: Implement proper error handling with user notification
            }
        }
    }
}

#Preview {
    NavigationStack {
        ParkDiscoveryView()
            .modelContainer(for: [Park.self, City.self], inMemory: true)
    }
}
