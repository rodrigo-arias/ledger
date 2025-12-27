//
//  MonthlyClose.swift
//  Ledger
//
//  Representa el cierre de un mes con snapshot de totales y arrastre.
//

import Foundation
import SwiftData

@Model
final class MonthlyClose {
    var id: UUID = UUID()
    var year: Int = 2_025
    var month: Int = 1 // 1-12
    var closedAt: Date = Date()

    // Snapshot de valores al momento del cierre
    var totalExpensesARS: Decimal = 0 // Total de gastos del mes en ARS
    var carryOverFromPrevious: Decimal = 0 // Arrastre del mes anterior
    var balanceAtClose: Decimal = 0 // Saldo pendiente al cierre (se arrastra)

    // Tipo de cambio usado para los cálculos
    var exchangeRateUsed: Decimal = 1_000

    // Estado del cierre
    var isClosed: Bool = true
    var updatedAt: Date = Date()

    var household: Household?
    @Relationship(deleteRule: .cascade, inverse: \Payment.monthlyClose)
    var payments: [Payment]?

    init(
        year: Int,
        month: Int,
        totalExpensesARS: Decimal,
        carryOverFromPrevious: Decimal,
        balanceAtClose: Decimal,
        exchangeRateUsed: Decimal
    ) {
        id = UUID()
        self.year = year
        self.month = month
        closedAt = Date()
        self.totalExpensesARS = totalExpensesARS
        self.carryOverFromPrevious = carryOverFromPrevious
        self.balanceAtClose = balanceAtClose
        self.exchangeRateUsed = exchangeRateUsed
        updatedAt = Date()
    }

    /// Identificador único del período (ej: "2025-01")
    var periodIdentifier: String {
        String(format: "%04d-%02d", year, month)
    }
}
