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
    var id: UUID
    var year: Int
    var month: Int  // 1-12
    var closedAt: Date

    // Snapshot de valores al momento del cierre
    var totalExpensesARS: Decimal      // Total de gastos del mes en ARS
    var carryOverFromPrevious: Decimal  // Arrastre del mes anterior
    var balanceAtClose: Decimal         // Saldo pendiente al cierre (se arrastra)

    // Tipo de cambio usado para los cálculos
    var exchangeRateUsed: Decimal

    // Estado del cierre
    var isClosed: Bool = true

    var household: Household?
    @Relationship(deleteRule: .cascade, inverse: \Payment.monthlyClose)
    var payments: [Payment] = []

    init(
        year: Int,
        month: Int,
        totalExpensesARS: Decimal,
        carryOverFromPrevious: Decimal,
        balanceAtClose: Decimal,
        exchangeRateUsed: Decimal
    ) {
        self.id = UUID()
        self.year = year
        self.month = month
        self.closedAt = Date()
        self.totalExpensesARS = totalExpensesARS
        self.carryOverFromPrevious = carryOverFromPrevious
        self.balanceAtClose = balanceAtClose
        self.exchangeRateUsed = exchangeRateUsed
    }

    /// Identificador único del período (ej: "2025-01")
    var periodIdentifier: String {
        String(format: "%04d-%02d", year, month)
    }
}
