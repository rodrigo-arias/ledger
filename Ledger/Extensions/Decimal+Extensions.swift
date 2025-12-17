//
//  Decimal+Extensions.swift
//  Ledger
//

import Foundation

extension Decimal {
    /// Formatea el monto con el símbolo de la moneda.
    /// Ej: "$45.000" o "US$100"
    func formatted(currency: Currency, showDecimals: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        formatter.minimumFractionDigits = showDecimals ? 2 : 0
        formatter.maximumFractionDigits = showDecimals ? 2 : 0

        let number = NSDecimalNumber(decimal: self)
        let formatted = formatter.string(from: number) ?? "\(self)"
        return "\(currency.symbol)\(formatted)"
    }

    /// Formatea como monto simple sin símbolo de moneda.
    func formattedAmount(showDecimals: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        formatter.minimumFractionDigits = showDecimals ? 2 : 0
        formatter.maximumFractionDigits = showDecimals ? 2 : 0

        let number = NSDecimalNumber(decimal: self)
        return formatter.string(from: number) ?? "\(self)"
    }

    /// Formatea como porcentaje.
    /// Ej: 0.78 -> "78%"
    func formattedPercentage() -> String {
        let percentage = self * 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0

        let number = NSDecimalNumber(decimal: percentage)
        let formatted = formatter.string(from: number) ?? "\(percentage)"
        return "\(formatted)%"
    }
}
