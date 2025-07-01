//
//  ContentView.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/19/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ParkDiscoveryView()
        }
    }
}


// Use a struct to work around #Preview limitations
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let schema = Schema([City.self, Park.self, Visit.self, User.self])
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        } catch {
            fatalError("Failed to create ModelContainer for preview: \(error)")
        }
        
        return ContentView()
            .environment(AppState(modelContainer: container, skipAutoLoad: true))
            .modelContainer(container)
    }
}
