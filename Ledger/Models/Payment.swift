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
    var id: UUID = UUID()
    var amount: Decimal = 0
    private var currencyRaw: String = "ARS"
    var date: Date = Date()

    var currency: Currency {
        get { Currency(rawValue: currencyRaw) ?? .ars }
        set { currencyRaw = newValue.rawValue }
    }

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var monthlyClose: MonthlyClose?

    init(
        amount: Decimal,
        currency: Currency,
        date: Date = Date()
    ) {
        id = UUID()
        self.amount = amount
        self.currency = currency
        self.date = date
        createdAt = Date()
        updatedAt = Date()
    }

    /// Calcula el valor del pago en ARS usando el tipo de cambio dado.
    func amountInARS(exchangeRate: Decimal) -> Decimal {
        switch currency {
        case .ars:
            amount
        case .usd:
            amount * exchangeRate
        }
    }
}
