//
//  Payment.swift
//  Ledger
//
//  Representa un pago del deudor al acreedor en el cierre de mes.
//

import Foundation
import SwiftData

@Model
final class Payment {
    var id: UUID
    var amount: Decimal
    var currency: Currency
    var date: Date
    var createdAt: Date

    var monthlyClose: MonthlyClose?

    init(
        amount: Decimal,
        currency: Currency,
        date: Date = Date()
    ) {
        self.id = UUID()
        self.amount = amount
        self.currency = currency
        self.date = date
        self.createdAt = Date()
    }

    /// Calcula el valor del pago en ARS usando el tipo de cambio dado.
    func amountInARS(exchangeRate: Decimal) -> Decimal {
        switch currency {
        case .ars:
            return amount
        case .usd:
            return amount * exchangeRate
        }
    }
}
