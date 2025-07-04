//
//  User.swift
//  Fog and Fern
//
//  Created by Kyle Olivo on 6/20/25.
//
import Foundation
import SwiftData

@Model
final class User {
    var id: UUID = UUID()
    var createdDate: Date = Date()
    
    // Relationships - Must be optional for CloudKit compatibility
    @Relationship(deleteRule: .cascade, inverse: \Visit.user)
    var visits: [Visit]? = []
    
    init(id: UUID = UUID()) {
        self.id = id
        self.createdDate = Date()
    }
}
