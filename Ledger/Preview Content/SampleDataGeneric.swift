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
        household.historicalDataUntilYear = 2_025
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
        let config1Dic = MonthlyConfig(year: 2_025, month: 12, exchangeRate: 1_400, incomeUSD: 5_000, fixedExpensesDebtorId: persona1.id)
        config1Dic.person = persona1
        config1Dic.household = household
        configs.append(config1Dic)

        let config2Dic = MonthlyConfig(year: 2_025, month: 12, exchangeRate: 1_400, incomeUSD: 3_000, fixedExpensesDebtorId: persona1.id)
        config2Dic.person = persona2
        config2Dic.household = household
        configs.append(config2Dic)

        // NOV 25
        let config1Nov = MonthlyConfig(year: 2_025, month: 11, exchangeRate: 1_380, incomeUSD: 5_000, fixedExpensesDebtorId: persona1.id)
        config1Nov.person = persona1
        config1Nov.household = household
        configs.append(config1Nov)

        let config2Nov = MonthlyConfig(year: 2_025, month: 11, exchangeRate: 1_380, incomeUSD: 3_000, fixedExpensesDebtorId: persona1.id)
        config2Nov.person = persona2
        config2Nov.household = household
        configs.append(config2Nov)

        // OCT 25
        let config1Oct = MonthlyConfig(year: 2_025, month: 10, exchangeRate: 1_350, incomeUSD: 5_000, fixedExpensesDebtorId: persona1.id)
        config1Oct.person = persona1
        config1Oct.household = household
        configs.append(config1Oct)

        let config2Oct = MonthlyConfig(year: 2_025, month: 10, exchangeRate: 1_350, incomeUSD: 3_000, fixedExpensesDebtorId: persona1.id)
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
            (2_025, 12, nil, 300_000, .ars, "Alquiler", "Alquiler", "alex", true),
            (2_025, 12, nil, 150_000, .ars, "Expensas", "Expensas", "alex", true),
            (2_025, 12, nil, 15_000, .ars, "Luz", "Servicios", "alex", true),
            (2_025, 12, nil, 8_000, .ars, "Gas", "Servicios", "alex", true),
            (2_025, 12, nil, 12_000, .ars, "Agua", "Servicios", "alex", true),
            (2_025, 12, 1, 45_000, .ars, "Supermercado", "Comida", "alex", false),
            (2_025, 12, 3, 38_000, .ars, "Verdulería", "Comida", "sam", false),
            (2_025, 12, 5, 52_000, .ars, "Carnicería", "Comida", "alex", false),
            (2_025, 12, 8, 28_000, .ars, "Delivery", "Comida", "sam", false),
            (2_025, 12, 10, 15_000, .ars, "Farmacia", "Extras", "alex", false),
            (2_025, 12, 12, 42_000, .ars, "Supermercado", "Comida", "sam", false),
            // NOV 25
            (2_025, 11, nil, 280_000, .ars, "Alquiler", "Alquiler", "alex", true),
            (2_025, 11, nil, 145_000, .ars, "Expensas", "Expensas", "alex", true),
            (2_025, 11, nil, 14_000, .ars, "Luz", "Servicios", "alex", true),
            (2_025, 11, nil, 7_500, .ars, "Gas", "Servicios", "alex", true),
            (2_025, 11, nil, 11_500, .ars, "Agua", "Servicios", "alex", true),
            (2_025, 11, 2, 48_000, .ars, "Supermercado", "Comida", "sam", false),
            (2_025, 11, 5, 35_000, .ars, "Verdulería", "Comida", "alex", false),
            (2_025, 11, 8, 55_000, .ars, "Carnicería", "Comida", "sam", false),
            (2_025, 11, 12, 32_000, .ars, "Delivery", "Comida", "alex", false),
            (2_025, 11, 15, 25_000, .ars, "Limpieza", "Extras", "alex", false),
            (2_025, 11, 18, 41_000, .ars, "Supermercado", "Comida", "sam", false),
            (2_025, 11, 22, 38_000, .ars, "Delivery", "Comida", "alex", false),
            (2_025, 11, 25, 25_000, .ars, "Limpieza", "Extras", "alex", false),
            (2_025, 11, nil, -50_000, .ars, "Devolución", "Extras", "sam", false),
            // OCT 25
            (2_025, 10, nil, 270_000, .ars, "Alquiler", "Alquiler", "sam", true),
            (2_025, 10, nil, 140_000, .ars, "Expensas", "Expensas", "sam", true),
            (2_025, 10, nil, 13_500, .ars, "Luz", "Servicios", "sam", true),
            (2_025, 10, nil, 7_000, .ars, "Gas", "Servicios", "sam", true),
            (2_025, 10, nil, 11_000, .ars, "Agua", "Servicios", "sam", true),
            (2_025, 10, 3, 52_000, .ars, "Supermercado", "Comida", "alex", false),
            (2_025, 10, 6, 33_000, .ars, "Verdulería", "Comida", "sam", false),
            (2_025, 10, 10, 48_000, .ars, "Carnicería", "Comida", "alex", false),
            (2_025, 10, 15, 29_000, .ars, "Delivery", "Comida", "sam", false),
            (2_025, 10, 20, 45_000, .ars, "Supermercado", "Comida", "alex", false),
            (2_025, 10, 25, 36_000, .ars, "Delivery", "Comida", "sam", false)
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
            return year == 2_025 && month == 11
        }
        let totalNov = novExpenses.reduce(Decimal.zero) { $0 + $1.amountInARS(exchangeRate: 1_380) }

        let closeNov = MonthlyClose(
            year: 2_025,
            month: 11,
            totalExpensesARS: totalNov,
            carryOverFromPrevious: 0,
            balanceAtClose: 150_000,
            exchangeRateUsed: 1_380
        )
        closeNov.household = household
        household.monthlyCloses = [closeNov]

        context.insert(household)
    }
}
