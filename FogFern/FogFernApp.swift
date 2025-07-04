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
            print("✅ CloudKit sync enabled - visits will sync across devices")
            return container
        } catch {
            print("⚠️ CloudKit initialization failed: \(error)")
            print("⚠️ Falling back to local storage - visits will not sync across devices")
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
            print("✅ Local storage initialized - data will be saved on this device only")
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
