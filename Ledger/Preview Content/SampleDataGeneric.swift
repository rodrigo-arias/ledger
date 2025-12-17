//
//  SampleDataGeneric.swift
//  Ledger
//
//  Datos de ejemplo genéricos para previews.
//

import Foundation
import SwiftData

@MainActor
enum SampleDataGeneric {
    static func createSampleData(in context: ModelContext) {
        // Household
        let household = Household(name: "Mi Casa")
        household.historicalDataUntilYear = 2025
        household.historicalDataUntilMonth = 10

        // Personas
        let persona1 = Person(name: "Alex", isCurrentUser: true)
        let persona2 = Person(name: "Sam", isCurrentUser: false)
        persona1.household = household
        persona2.household = household
        household.members = [persona1, persona2]

        // Categorías
        let categories = Category.defaultCategories.enumerated().map { index, cat in
            let category = Category(name: cat.name, emoji: cat.emoji, sortOrder: index)
            category.household = household
            return category
        }
        household.categories = categories

        // Configs mensuales
        var configs: [MonthlyConfig] = []

        // DIC 25
        let config1Dic = MonthlyConfig(year: 2025, month: 12, exchangeRate: 1400, incomeUSD: 5000, fixedExpensesDebtorId: persona1.id)
        config1Dic.person = persona1
        config1Dic.household = household
        configs.append(config1Dic)

        let config2Dic = MonthlyConfig(year: 2025, month: 12, exchangeRate: 1400, incomeUSD: 3000, fixedExpensesDebtorId: persona1.id)
        config2Dic.person = persona2
        config2Dic.household = household
        configs.append(config2Dic)

        // NOV 25
        let config1Nov = MonthlyConfig(year: 2025, month: 11, exchangeRate: 1380, incomeUSD: 5000, fixedExpensesDebtorId: persona1.id)
        config1Nov.person = persona1
        config1Nov.household = household
        configs.append(config1Nov)

        let config2Nov = MonthlyConfig(year: 2025, month: 11, exchangeRate: 1380, incomeUSD: 3000, fixedExpensesDebtorId: persona1.id)
        config2Nov.person = persona2
        config2Nov.household = household
        configs.append(config2Nov)

        // OCT 25
        let config1Oct = MonthlyConfig(year: 2025, month: 10, exchangeRate: 1350, incomeUSD: 5000, fixedExpensesDebtorId: persona1.id)
        config1Oct.person = persona1
        config1Oct.household = household
        configs.append(config1Oct)

        let config2Oct = MonthlyConfig(year: 2025, month: 10, exchangeRate: 1350, incomeUSD: 3000, fixedExpensesDebtorId: persona1.id)
        config2Oct.person = persona2
        config2Oct.household = household
        configs.append(config2Oct)

        household.monthlyConfigs = configs

        // Categorías
        let alquiler = categories.first { $0.name == "Alquiler" }
        let expensas = categories.first { $0.name == "Expensas" }
        let servicios = categories.first { $0.name == "Servicios" }
        let comida = categories.first { $0.name == "Comida" }
        let extras = categories.first { $0.name == "Extras" }

        // Gastos de ejemplo
        let expensesData: [(Int, Int, Int?, Decimal, Currency, String, String, String, Bool)] = [
            // DIC 25
            (2025, 12, nil, 300000, .ars, "Alquiler", "Alquiler", "alex", true),
            (2025, 12, nil, 150000, .ars, "Expensas", "Expensas", "alex", true),
            (2025, 12, nil, 15000, .ars, "Luz", "Servicios", "alex", true),
            (2025, 12, nil, 8000, .ars, "Gas", "Servicios", "alex", true),
            (2025, 12, nil, 12000, .ars, "Agua", "Servicios", "alex", true),
            (2025, 12, 1, 45000, .ars, "Supermercado", "Comida", "alex", false),
            (2025, 12, 3, 38000, .ars, "Verdulería", "Comida", "sam", false),
            (2025, 12, 5, 52000, .ars, "Carnicería", "Comida", "alex", false),
            (2025, 12, 8, 28000, .ars, "Delivery", "Comida", "sam", false),
            (2025, 12, 10, 15000, .ars, "Farmacia", "Extras", "alex", false),
            (2025, 12, 12, 42000, .ars, "Supermercado", "Comida", "sam", false),
            // NOV 25
            (2025, 11, nil, 280000, .ars, "Alquiler", "Alquiler", "alex", true),
            (2025, 11, nil, 145000, .ars, "Expensas", "Expensas", "alex", true),
            (2025, 11, nil, 14000, .ars, "Luz", "Servicios", "alex", true),
            (2025, 11, nil, 7500, .ars, "Gas", "Servicios", "alex", true),
            (2025, 11, nil, 11500, .ars, "Agua", "Servicios", "alex", true),
            (2025, 11, 2, 48000, .ars, "Supermercado", "Comida", "sam", false),
            (2025, 11, 5, 35000, .ars, "Verdulería", "Comida", "alex", false),
            (2025, 11, 8, 55000, .ars, "Carnicería", "Comida", "sam", false),
            (2025, 11, 12, 32000, .ars, "Delivery", "Comida", "alex", false),
            (2025, 11, 15, 25000, .ars, "Limpieza", "Extras", "alex", false),
            (2025, 11, 18, 41000, .ars, "Supermercado", "Comida", "sam", false),
            (2025, 11, 22, 38000, .ars, "Delivery", "Comida", "alex", false),
            (2025, 11, 25, 25000, .ars, "Limpieza", "Extras", "alex", false),
            (2025, 11, nil, -50000, .ars, "Devolución", "Extras", "sam", false),
            // OCT 25
            (2025, 10, nil, 270000, .ars, "Alquiler", "Alquiler", "sam", true),
            (2025, 10, nil, 140000, .ars, "Expensas", "Expensas", "sam", true),
            (2025, 10, nil, 13500, .ars, "Luz", "Servicios", "sam", true),
            (2025, 10, nil, 7000, .ars, "Gas", "Servicios", "sam", true),
            (2025, 10, nil, 11000, .ars, "Agua", "Servicios", "sam", true),
            (2025, 10, 3, 52000, .ars, "Supermercado", "Comida", "alex", false),
            (2025, 10, 6, 33000, .ars, "Verdulería", "Comida", "sam", false),
            (2025, 10, 10, 48000, .ars, "Carnicería", "Comida", "alex", false),
            (2025, 10, 15, 29000, .ars, "Delivery", "Comida", "sam", false),
            (2025, 10, 20, 45000, .ars, "Supermercado", "Comida", "alex", false),
            (2025, 10, 25, 36000, .ars, "Delivery", "Comida", "sam", false),
        ]

        let categoryMap: [String: Category?] = [
            "Alquiler": alquiler,
            "Expensas": expensas,
            "Servicios": servicios,
            "Comida": comida,
            "Extras": extras
        ]

        var allExpenses: [Expense] = []
        for (year, month, day, amount, currency, concept, categoryName, personName, isFixed) in expensesData {
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = day ?? 1
            let expenseDate = Calendar.current.date(from: components)

            let expense = Expense(
                amount: amount,
                currency: currency,
                concept: concept,
                date: expenseDate,
                hasSpecificDate: day != nil
            )
            expense.category = categoryMap[categoryName] ?? extras
            expense.paidBy = personName == "alex" ? persona1 : persona2
            expense.household = household
            expense.isFixedExpense = isFixed

            allExpenses.append(expense)
        }

        household.expenses = allExpenses

        // Cierre NOV 2025
        let novExpenses = allExpenses.filter {
            let (year, month) = $0.yearMonth
            return year == 2025 && month == 11
        }
        let totalNov = novExpenses.reduce(Decimal.zero) { $0 + $1.amountInARS(exchangeRate: 1380) }

        let closeNov = MonthlyClose(
            year: 2025,
            month: 11,
            totalExpensesARS: totalNov,
            carryOverFromPrevious: 0,
            balanceAtClose: 150000,
            exchangeRateUsed: 1380
        )
        closeNov.household = household
        household.monthlyCloses = [closeNov]

        context.insert(household)
    }
}
