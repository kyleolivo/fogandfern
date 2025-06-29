//
//  AppState.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/20/25.
//

import Foundation
import SwiftData
import CoreLocation

@Observable
@MainActor
class AppState {
    private let modelContainer: ModelContainer
    
    // Repositories
    let parkRepository: ParkRepository
    let userRepository: UserRepository
    
    // Current state
    var currentUser: User?
    var currentCity: City?
    var parks: [Park] = []
    var isLoading = false
    var errorMessage: String?
    
    // Location
    var userLocation: CLLocation?
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.parkRepository = ParkRepository(modelContainer: modelContainer)
        self.userRepository = UserRepository(modelContainer: modelContainer)
        
        Task { @MainActor in
            await loadInitialData()
        }
    }
    
    func loadInitialData() async {
        isLoading = true
        
        do {
            // Load or create user using Apple's recommended pattern
            currentUser = try await userRepository.getCurrentUser()
            
            // Set up San Francisco as default city
            currentCity = City.sanFrancisco
            
            // Insert San Francisco into database if it doesn't exist
            try await ensureCityExists(City.sanFrancisco)
            
            // Load parks
            await loadParks()
            
        } catch {
            errorMessage = "Failed to load initial data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadParks() async {
        guard let city = currentCity else { return }
        
        isLoading = true
        
        do {
            parks = try await parkRepository.getAllParksForUI(for: city)
        } catch {
            errorMessage = "Failed to load parks: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshParks() async {
        guard let city = currentCity else { return }
        
        do {
            try await parkRepository.refreshParkData(for: city)
            await loadParks()
        } catch {
            errorMessage = "Failed to refresh parks: \(error.localizedDescription)"
        }
    }
    
    private func ensureCityExists(_ city: City) async throws {
        let context = modelContainer.mainContext
        let cityName = city.name
        
        let descriptor = FetchDescriptor<City>(
            predicate: #Predicate<City> { c in
                c.name == cityName
            }
        )
        
        let existingCities = try context.fetch(descriptor)
        
        if existingCities.isEmpty {
            context.insert(city)
            try context.save()
        } else {
            currentCity = existingCities.first
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}