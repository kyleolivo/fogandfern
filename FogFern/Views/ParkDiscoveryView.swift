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
    @Query private var allParks: [Park]
    @Query private var users: [User]
    @Query private var visits: [Visit]
    @StateObject private var locationManager = LocationManager()
    @State private var mapPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    @State private var selectedPark: Park?
    @State private var selectedCategories: Set<ParkCategory> = [.destination]
    @State private var showingFilterSheet = false
    
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
            print("Error saving visit: \(error)")
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
        .sheet(item: $selectedPark) { park in
            ParkDetailOverlay(park: park, onMarkVisited: markAsVisited)
        }
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingFilterSheet = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(selectedCategories.count > 1 ? .blue : .primary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    centerOnUserLocation()
                } label: {
                    Image(systemName: "location")
                        .foregroundColor(.blue)
                }
                .disabled(!locationManager.isLocationAvailable)
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterCategoriesView(selectedCategories: $selectedCategories)
        }
        .onAppear {
            loadParks()
            ensureCurrentUserExists()
            locationManager.requestLocationPermission()
            
            // Debug: Print park count and check for duplicates
            print("Total parks loaded: \(allParks.count)")
            let parkNames = allParks.map { $0.name }
            let uniqueNames = Set(parkNames)
            if parkNames.count != uniqueNames.count {
                print("WARNING: Duplicate park names detected!")
                let duplicates = parkNames.filter { name in
                    parkNames.filter { $0 == name }.count > 1
                }
                print("Duplicates: \(Set(duplicates))")
            }
            
            // Debug: Check for coordinate duplicates in filtered parks
            let coordinates = parks.map { "\($0.latitude),\($0.longitude)" }
            let uniqueCoordinates = Set(coordinates)
            if coordinates.count != uniqueCoordinates.count {
                print("WARNING: Multiple parks at same coordinates!")
                let coordinateGroups = Dictionary(grouping: parks, by: { "\($0.latitude),\($0.longitude)" })
                for (coord, parkList) in coordinateGroups where parkList.count > 1 {
                    print("  Coordinate \(coord): \(parkList.map { $0.name })")
                }
            }
        }
    }
    
    @State private var hasLoadedParks = false
    
    private func loadParks() {
        // Only load parks once during the app session
        guard !hasLoadedParks else {
            print("Parks already loaded, skipping...")
            return
        }
        
        print("Loading parks for the first time...")
        hasLoadedParks = true
        
        do {
            // ParkDataLoader will create its own city instance
            try ParkDataLoader.loadParks(into: modelContext, for: City.sanFrancisco)
        } catch {
            print("Error loading parks: \(error)")
            hasLoadedParks = false // Reset so we can try again
            try? modelContext.save()
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
                print("Error creating user: \(error)")
            }
        }
    }
}

struct ParkDetailOverlay: View {
    let park: Park
    let onMarkVisited: (Park) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var visits: [Visit]
    @Query private var users: [User]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero Image
                    if UIImage(named: park.imageName) != nil {
                        Image(park.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipped()
                    } else {
                        // Placeholder image
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.mint.opacity(0.3), .green.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .overlay(
                                VStack {
                                    Image(systemName: "tree.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("No Image Available")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Header section
                        VStack(alignment: .leading, spacing: 8) {
                            Text(park.name)
                                .font(.largeTitle)
                                .bold()
                            
                            Text(park.address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 16) {
                                Label(park.formattedAcreage, systemImage: "leaf.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Label(park.category.displayName, systemImage: park.category.systemImageName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    
                    Divider()
                    
                    // Mark as visited section
                    Button(action: {
                        onMarkVisited(park)
                    }) {
                        HStack {
                            Image(systemName: hasVisited(park) ? "checkmark.circle.fill" : "plus.circle")
                            Text(hasVisited(park) ? "Visited" : "Mark as Visited")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hasVisited(park) ? .green : .blue)
                        .cornerRadius(10)
                    }
                    
                    Divider()
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                        
                        Text(park.fullDescription)
                            .font(.body)
                    }
                    
                    
                    
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle(park.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func hasVisited(_ park: Park) -> Bool {
        guard let currentUser = users.first else { return false }
        return visits.contains { visit in
            visit.park.id == park.id && visit.user.id == currentUser.id
        }
    }
}

struct FilterCategoriesView: View {
    @Binding var selectedCategories: Set<ParkCategory>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Choose which types of parks to show on the map.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .listRowBackground(Color.clear)
                }
                
                Section("Park Categories") {
                    ForEach(ParkCategory.mainCategories, id: \.self) { category in
                        HStack {
                            Image(systemName: category.systemImageName)
                                .foregroundColor(.mint)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.displayName)
                                    .font(.body)
                                
                                Text(categoryDescription(for: category))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedCategories.contains(category) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .font(.body.weight(.medium))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleCategory(category)
                        }
                    }
                }
                
                Section {
                    Button("Show All Categories") {
                        selectedCategories = Set(ParkCategory.mainCategories)
                    }
                    .foregroundColor(.blue)
                    
                    Button("Reset to Default") {
                        selectedCategories = [.destination]
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Filter Parks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleCategory(_ category: ParkCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
        
        // Ensure at least one category is always selected
        if selectedCategories.isEmpty {
            selectedCategories.insert(.destination)
        }
    }
    
    private func categoryDescription(for category: ParkCategory) -> String {
        switch category {
        case .destination:
            return "Large regional parks with major attractions"
        case .neighborhood:
            return "Local community parks with playgrounds and sports"
        case .mini:
            return "Small neighborhood spaces and pocket parks"
        case .plaza:
            return "Urban squares and civic gathering spaces"
        case .garden:
            return "Community gardens and green spaces"
        default:
            return category.displayName
        }
    }
}

// Extension for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    var isLocationAvailable: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }
    
    func requestLocationPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        } else {
            manager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

#Preview {
    NavigationView {
        ParkDiscoveryView()
            .modelContainer(for: [Park.self, City.self], inMemory: true)
    }
}