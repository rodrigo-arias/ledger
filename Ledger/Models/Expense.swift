//
//  Expense.swift
//  Ledger
//

import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID = UUID()
    var amount: Decimal = 0
    private var currencyRaw: String = "ARS"
    var concept: String = ""

    var currency: Currency {
        get { Currency(rawValue: currencyRaw) ?? .ars }
        set { currencyRaw = newValue.rawValue }
    }

    var note: String?
    var date: Date?
    var hasSpecificDate: Bool = true
    var isFixedExpense: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

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
        id = UUID()
        self.amount = amount
        self.currency = currency
        self.concept = concept
        self.note = note
        self.date = date
        self.hasSpecificDate = hasSpecificDate
        createdAt = Date()
        updatedAt = Date()
    }

    /// Año y mes del gasto (para agrupar y buscar config).
    /// Si no tiene fecha, usa la fecha de creación.
    var yearMonth: (year: Int, month: Int) {
        let calendar = Calendar.current
        let effectiveDate = date ?? createdAt
        return (
            calendar.component(.year, from: effectiveDate),
            calendar.component(.month, from: effectiveDate)
        )
    }

    /// Convierte el monto a ARS usando el tipo de cambio del mes.
    /// Si el gasto ya está en ARS, retorna el monto original.
    func amountInARS(exchangeRate: Decimal) -> Decimal {
        switch currency {
        case .ars:
            amount
        case .usd:
            amount * exchangeRate
        }
    }
}
