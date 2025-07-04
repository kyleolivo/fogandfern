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
    @State private var showingTipView = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Park Categories") {
                    ForEach(ParkCategory.allCases, id: \.self) { category in
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
                        .accessibilityIdentifier("categoryFilter_\(category.rawValue)")
                        .accessibilityLabel("\(category.displayName) filter")
                        .accessibilityValue(selectedCategories.contains(category) ? "selected" : "not selected")
                    }
                }
                
                Section {
                    Button("Show All Categories") {
                        selectedCategories = Set(ParkCategory.allCases)
                    }
                    .foregroundColor(.blue)
                    
                    Button("Reset to Default") {
                        selectedCategories = [.destination]
                    }
                    .foregroundColor(.blue)
                }
                
                Section {
                    VStack(spacing: 12) {
                        Text("Made with ❤️ in San Francisco.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Buy me a ☕️") {
                            showingTipView = true
                        }
                        .foregroundStyle(.white)
                        .font(.system(size: 16, weight: .medium))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.mint, Color.mint.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
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
            .sheet(isPresented: $showingTipView) {
                TipSelectionView()
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
        }
    }
}
