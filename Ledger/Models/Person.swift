//
//  Person.swift
//  Ledger
//

import Foundation
import SwiftData

@Model
final class Person {
    var id: UUID = UUID()
    var name: String = ""
    var updatedAt: Date = Date()

    var household: Household?

    @Relationship(inverse: \Expense.paidBy)
    var expensesPaid: [Expense]?

    @Relationship(inverse: \MonthlyConfig.person)
    var monthlyConfigs: [MonthlyConfig]?

    init(name: String) {
        id = UUID()
        self.name = name
        updatedAt = Date()
    }

    var isCurrentUser: Bool {
        CurrentUserManager.shared.isCurrentUser(self)
    }
}
