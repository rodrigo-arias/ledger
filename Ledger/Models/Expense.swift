//
//  Expense.swift
//  Ledger
//

import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID
    var amount: Decimal
    var currency: Currency
    var concept: String
    var note: String?
    var date: Date?
    var hasSpecificDate: Bool = true
    var isFixedExpense: Bool = false
    var createdAt: Date
    var updatedAt: Date

    var category: Category?
    var paidBy: Person?
    var household: Household?

    init(
        amount: Decimal,
        currency: Currency = .ars,
        concept: String,
        note: String? = nil,
        date: Date? = nil,
        hasSpecificDate: Bool = true
    ) {
        self.id = UUID()
        self.amount = amount
        self.currency = currency
        self.concept = concept
        self.note = note
        self.date = date
        self.hasSpecificDate = hasSpecificDate
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Año y mes del gasto (para agrupar y buscar config).
    /// Si no tiene fecha, usa la fecha de creación.
    var yearMonth: (year: Int, month: Int) {
        let calendar = Calendar.current
        let effectiveDate = date ?? createdAt
        return (calendar.component(.year, from: effectiveDate),
                calendar.component(.month, from: effectiveDate))
    }

    /// Convierte el monto a ARS usando el tipo de cambio del mes.
    /// Si el gasto ya está en ARS, retorna el monto original.
    func amountInARS(exchangeRate: Decimal) -> Decimal {
        switch currency {
        case .ars:
            return amount
        case .usd:
            return amount * exchangeRate
        }
    }
}
