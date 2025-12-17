//
//  Category.swift
//  Ledger
//

import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String
    var emoji: String?
    var sortOrder: Int

    var household: Household?

    @Relationship(inverse: \Expense.category)
    var expenses: [Expense] = []

    init(name: String, emoji: String? = nil, sortOrder: Int = 0) {
        id = UUID()
        self.name = name
        self.emoji = emoji
        self.sortOrder = sortOrder
    }

    var displayName: String {
        if let emoji {
            return "\(emoji) \(name)"
        }
        return name
    }

    static let defaultCategories: [(name: String, emoji: String)] = [
        ("Alquiler", "🏠"),
        ("Expensas", "🏢"),
        ("Servicios", "💡"),
        ("Comida", "🍽️"),
        ("Extras", "🛒"),
        ("Arreglos", "🔧")
    ]
}
