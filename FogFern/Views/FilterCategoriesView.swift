//
//  FilterCategoriesView.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/28/25.
//

import SwiftUI

struct FilterCategoriesView: View {
    @Binding var selectedCategories: Set<ParkCategory>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
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