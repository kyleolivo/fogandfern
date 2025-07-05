//
//  FogFernApp.swift
//  FogFern
//
//  Created by Kyle Olivo on 6/22/25.
//

import SwiftUI
import SwiftData
import UIKit

// AppDelegate to handle orientation restrictions
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

@main
struct FogFernApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var sharedModelContainer: ModelContainer = {
        // Try CloudKit setup first with separate configurations
        do {
            let cloudKitConfig = ModelConfiguration(
                "CloudKitData",
                schema: Schema([Visit.self, User.self]),
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            
            let localConfig = ModelConfiguration(
                "LocalData", 
                schema: Schema([Park.self, City.self]),
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            
            let container = try ModelContainer(
                for: Visit.self, User.self, Park.self, City.self,
                configurations: cloudKitConfig, localConfig
            )
            return container
        } catch {
            // CloudKit failed, fall back to all local storage
        }
        
        // Fallback: All data stored locally (no CloudKit)
        do {
            let fallbackConfig = ModelConfiguration(
                schema: Schema([Visit.self, User.self, Park.self, City.self]),
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            
            let container = try ModelContainer(
                for: Visit.self, User.self, Park.self, City.self,
                configurations: fallbackConfig
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
                .onAppear {
                    // Ensure the app only supports portrait orientation
                    AppDelegate.orientationLock = .portrait
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
