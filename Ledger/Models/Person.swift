//
//  Person.swift
//  Ledger
//

import Foundation
import SwiftData

@Model
final class Person {
    var id: UUID
    var name: String
    var isCurrentUser: Bool

    var household: Household?

    @Relationship(inverse: \Expense.paidBy)
    var expensesPaid: [Expense] = []

    @Relationship(inverse: \MonthlyConfig.person)
    var monthlyConfigs: [MonthlyConfig] = []

    init(name: String, isCurrentUser: Bool = false) {
        id = UUID()
        self.name = name
        self.isCurrentUser = isCurrentUser
    }
}
