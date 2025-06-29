//
//  ParkDetailOverlay.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/28/25.
//

import SwiftUI
import SwiftData

struct ParkDetailOverlay: View {
    let park: Park
    let onMarkVisited: (Park) -> Void
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Visit.timestamp, order: .reverse) private var visits: [Visit]
    @Query(sort: \User.createdDate) private var users: [User]
    
    var body: some View {
        NavigationStack {
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