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
            City.self,
            Park.self,
            Visit.self,
            User.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
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
