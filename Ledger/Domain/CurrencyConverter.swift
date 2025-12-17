//
//  CurrencyConverter.swift
//  Ledger
//

import Foundation

enum CurrencyConverter {
    /// Convierte un monto a ARS usando el tipo de cambio dado.
    static func toARS(amount: Decimal, currency: Currency, exchangeRate: Decimal) -> Decimal {
        switch currency {
        case .ars:
            return amount
        case .usd:
            return amount * exchangeRate
        }
    }

    /// Convierte un monto de ARS a USD usando el tipo de cambio dado.
    static func toUSD(amountARS: Decimal, exchangeRate: Decimal) -> Decimal {
        guard exchangeRate > 0 else { return 0 }
        return amountARS / exchangeRate
    }

    /// Calcula el total en ARS de un pago multi-moneda.
    static func paymentTotalInARS(amountARS: Decimal?, amountUSD: Decimal?, exchangeRate: Decimal) -> Decimal {
        let ars = amountARS ?? 0
        let usdInARS = toARS(amount: amountUSD ?? 0, currency: .usd, exchangeRate: exchangeRate)
        return ars + usdInARS
    }
}
