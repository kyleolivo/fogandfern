//
//  ParkListRow.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/28/25.
//

import SwiftUI

struct ParkListRow: View {
    let park: Park
    let isVisited: Bool
    let onTap: () -> Void
    let onMarkVisited: ((Park) -> Void)?
    
    var body: some View {
        HStack {
            // Park category icon
            Image(systemName: park.category.systemImageName)
                .foregroundColor(.mint)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(park.name)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text(park.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(park.formattedAcreage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Visit status button
            Button(action: {
                onMarkVisited?(park)
            }) {
                Image(systemName: isVisited ? "checkmark.circle.fill" : "plus.circle")
                    .foregroundColor(isVisited ? .green : .blue)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}