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

struct ParkListView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        List {
            if appState.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading parks...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            } else if appState.parks.isEmpty {
                Text("No parks found")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(appState.parks) { park in
                    NavigationLink {
                        // TODO: Replace with new ParkDetailView when needed
                        Text("Park Detail - \(park.name)")
                    } label: {
                        ParkRowView(park: park)
                    }
                }
            }
        }
        .navigationTitle("Parks")
#if os(macOS)
        .navigationSplitViewColumnWidth(min: 250, ideal: 300)
#endif
        .toolbar {
            ToolbarItem {
                Button(action: refreshParks) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(appState.isLoading)
            }
        }
        .refreshable {
            await appState.refreshParks()
        }
    }
    
    private func refreshParks() {
        Task {
            await appState.refreshParks()
        }
    }
}

struct ParkRowView: View {
    let park: Park
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(park.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if park.isFeatured {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
                
                Image(systemName: park.category.systemImageName)
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            
            Text(park.shortDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            HStack {
                Label(park.formattedAcreage, systemImage: "leaf.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Label(park.category.displayName, systemImage: park.category.systemImageName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}


struct ParkListEmptyStateView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Welcome to Fog & Fern")
                .font(.title2)
                .bold()
            
            Text("Discover amazing parks in San Francisco")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Load Parks") {
                Task {
                    await appState.loadParks()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(appState.isLoading)
        }
        .padding()
    }
}

#Preview {
    let schema = Schema([City.self, Park.self, Visit.self, User.self])
    let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    
    ContentView()
        .environment(AppState(modelContainer: container))
        .modelContainer(container)
}
