//
//  Household.swift
//  Ledger
//

import Foundation
import SwiftData

@Model
final class Household {
    var id: UUID
    var name: String
    var createdAt: Date

    // Meses hasta esta fecha (inclusive) son solo históricos
    var historicalDataUntilYear: Int?
    var historicalDataUntilMonth: Int?

    @Relationship(deleteRule: .cascade, inverse: \Person.household)
    var members: [Person] = []

    @Relationship(deleteRule: .cascade, inverse: \Category.household)
    var categories: [Category] = []

    @Relationship(deleteRule: .cascade, inverse: \MonthlyConfig.household)
    var monthlyConfigs: [MonthlyConfig] = []

    @Relationship(deleteRule: .cascade, inverse: \Expense.household)
    var expenses: [Expense] = []

    @Relationship(deleteRule: .cascade, inverse: \MonthlyClose.household)
    var monthlyCloses: [MonthlyClose] = []

    init(name: String) {
        id = UUID()
        self.name = name
        createdAt = Date()
        historicalDataUntilYear = nil
        historicalDataUntilMonth = nil
    }

    /// Verifica si un mes es histórico
    func isHistoricalMonth(year: Int, month: Int) -> Bool {
        guard let histYear = historicalDataUntilYear,
              let histMonth = historicalDataUntilMonth
        else {
            return false
        }

        if year < histYear {
            return true
        } else if year == histYear {
            return month <= histMonth
        }
        return false
    }
}
