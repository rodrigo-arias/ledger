//
//  Formatters.swift
//  Ledger
//

import Foundation

enum Formatters {
    /// Formatter para montos en ARS.
    static let arsAmount: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// Formatter para montos en USD (con decimales).
    static let usdAmount: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    /// Formatter para tipo de cambio.
    static let exchangeRate: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    /// Formatter para fechas cortas.
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_AR")
        formatter.dateFormat = "d/M"
        return formatter
    }()

    /// Formatter para fechas medias.
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_AR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Formatea input de monto con separadores de miles.
    /// Ej: "45000" → "45.000", "1500000,50" → "1.500.000,50", "-5000" → "-5.000"
    static func formatAmountInput(_ input: String) -> String {
        let isNegative = input.hasPrefix("-")
        let cleaned = input.filter { $0.isNumber || $0 == "," }
        let parts = cleaned.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
        let integerPart = String(parts.first ?? "")
        let decimalPart = parts.count > 1 ? String(parts[1]) : nil

        guard let number = Int(integerPart) else {
            let prefix = isNegative ? "-" : ""
            return decimalPart != nil ? "\(prefix),\(decimalPart!)" : prefix
        }

        let formatted = arsAmount.string(from: NSNumber(value: number)) ?? integerPart
        let prefix = isNegative ? "-" : ""

        if let decimal = decimalPart {
            return "\(prefix)\(formatted),\(decimal)"
        }
        return "\(prefix)\(formatted)"
    }

    /// Parsea un string formateado a Decimal.
    /// Ej: "45.000,50" → Decimal(45000.50). Retorna nil si no es válido.
    static func parseAmount(_ input: String) -> Decimal? {
        let cleaned = input
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Decimal(string: cleaned)
    }
}
