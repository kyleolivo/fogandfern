//
//  ParkFilteredListView.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/28/25.
//

import SwiftUI

struct ParkFilteredListView: View {
    let visitedParks: [Park]
    let unvisitedParks: [Park]
    let selectedCategories: Set<ParkCategory>
    let onParkSelected: (Park) -> Void
    let onMarkVisited: (Park) -> Void
    
    var body: some View {
        List {
            if !visitedParks.isEmpty {
                Section("✅ Visited Parks (\(visitedParks.count))") {
                    ForEach(visitedParks) { park in
                        ParkListRow(
                            park: park, 
                            isVisited: true,
                            onTap: { onParkSelected(park) },
                            onMarkVisited: onMarkVisited
                        )
                    }
                }
                .accessibilityIdentifier("visitedParksSection")
            }
            
            if !unvisitedParks.isEmpty {
                Section("📍 Unvisited Parks (\(unvisitedParks.count))") {
                    ForEach(unvisitedParks) { park in
                        ParkListRow(
                            park: park, 
                            isVisited: false,
                            onTap: { onParkSelected(park) },
                            onMarkVisited: onMarkVisited
                        )
                    }
                }
                .accessibilityIdentifier("unvisitedParksSection")
            }
            
            if visitedParks.isEmpty && unvisitedParks.isEmpty {
                Section {
                    Text("No parks match your current filter")
                        .foregroundColor(.secondary)
                        .italic()
                        .accessibilityIdentifier("noParksMessage")
                }
            }
        }
        .listStyle(PlainListStyle())
        .accessibilityIdentifier("parksList")
    }
}
