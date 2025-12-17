//
//  MonthlyConfig.swift
//  Ledger
//
//  Configuración mensual: tipo de cambio e ingreso por persona.
//  Se crea un registro por persona por mes.
//

import Foundation
import SwiftData

@Model
final class MonthlyConfig {
    var id: UUID
    var year: Int
    var month: Int // 1-12
    var exchangeRate: Decimal // ARS por USD
    var incomeUSD: Decimal // Ingreso de esta persona en USD
    var fixedExpensesDebtorId: UUID? // ID de la persona que debe los gastos fijos este mes

    var person: Person?
    var household: Household?

    init(year: Int, month: Int, exchangeRate: Decimal, incomeUSD: Decimal, fixedExpensesDebtorId: UUID? = nil) {
        id = UUID()
        self.year = year
        self.month = month
        self.exchangeRate = exchangeRate
        self.incomeUSD = incomeUSD
        self.fixedExpensesDebtorId = fixedExpensesDebtorId
    }

    /// Calcula el porcentaje de aporte de esta persona para el mes.
    /// Requiere acceso a todos los configs del mismo mes.
    func contributionPercentage(allConfigsForMonth: [MonthlyConfig]) -> Decimal {
        let totalIncome = allConfigsForMonth.reduce(Decimal.zero) { $0 + $1.incomeUSD }
        guard totalIncome > 0 else { return 0.5 } // 50% por defecto si no hay ingresos
        return incomeUSD / totalIncome
    }
}
