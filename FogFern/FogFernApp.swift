//
//  FogFernApp.swift
//  FogFern
//
//  Created by Kyle Olivo on 6/22/25.
//

import SwiftUI
import SwiftData

@main
struct FogFernApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Visit.self,
            User.self, 
            Park.self,
            City.self
        ])
        
        // Try CloudKit first
        do {
            let cloudKitConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            let container = try ModelContainer(
                for: schema,
                configurations: [cloudKitConfig]
            )
            return container
        } catch {
            // CloudKit failed, fall back to local storage
        }
        
        // Fallback to local storage (persistent, no CloudKit)
        do {
            let localConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(
                for: schema,
                configurations: [localConfig]
            )
            return container
        } catch {
            fatalError("Cannot create persistent storage. Error: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AppState(modelContainer: sharedModelContainer))
        }
        .modelContainer(sharedModelContainer)
    }
}
