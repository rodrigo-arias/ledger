//
//  BalanceCalculator.swift
//  Ledger
//
//  Calcula el balance mensual entre dos personas.
//

import Foundation

/// Resultado del cálculo de balance mensual.
struct MonthlyBalance {
    let totalExpensesARS: Decimal
    let totalExpensesUSD: Decimal
    let byPerson: [UUID: PersonBalance]
    let carryOver: Decimal
    let netBalance: Decimal  // Positivo = persona 1 debe cobrar
    let creditor: Person?
    let debtor: Person?
    let byCategory: [UUID: CategoryBalance]
}

/// Balance de una persona.
struct PersonBalance {
    let person: Person
    let paid: Decimal       // Lo que pagó (ARS)
    let expected: Decimal   // Lo que debería según %
    let difference: Decimal // paid - expected (+ = a favor, - = en contra)
    let contributionPercent: Decimal
}

/// Balance por categoría.
struct CategoryBalance {
    let category: Category
    let total: Decimal
    let byPerson: [UUID: Decimal]
}

enum BalanceCalculator {

    /// Calcula el balance de un mes.
    static func calculate(
        expenses: [Expense],
        configs: [MonthlyConfig],
        previousClose: MonthlyClose?,
        exchangeRate: Decimal
    ) -> MonthlyBalance {
        // Totales generales
        let totalARS = expenses.reduce(Decimal.zero) { sum, expense in
            sum + expense.amountInARS(exchangeRate: exchangeRate)
        }

        let totalUSD = expenses
            .filter { $0.currency == .usd }
            .reduce(Decimal.zero) { $0 + $1.amount }

        // Total de ingresos para calcular porcentajes
        let totalIncome = configs.reduce(Decimal.zero) { $0 + $1.incomeUSD }

        // Balance por persona
        var byPerson: [UUID: PersonBalance] = [:]

        for config in configs {
            guard let person = config.person else { continue }

            let percent = totalIncome > 0 ? config.incomeUSD / totalIncome : Decimal(0.5)
            let expected = totalARS * percent

            let paid = expenses
                .filter { $0.paidBy?.id == person.id }
                .reduce(Decimal.zero) { $0 + $1.amountInARS(exchangeRate: exchangeRate) }

            byPerson[person.id] = PersonBalance(
                person: person,
                paid: paid,
                expected: expected,
                difference: paid - expected,
                contributionPercent: percent
            )
        }

        // Arrastre del mes anterior
        let carryOver = previousClose?.balanceAtClose ?? Decimal.zero

        // Balance neto (solo funciona con 2 personas)
        let balances = byPerson.values.map { $0.difference }
        let netBalance = (balances.first ?? 0) + carryOver

        // Determinar acreedor y deudor
        let sortedPersons = byPerson.values.sorted { $0.difference > $1.difference }
        let creditor = sortedPersons.first?.difference ?? 0 > 0 ? sortedPersons.first?.person : nil
        let debtor = sortedPersons.last?.difference ?? 0 < 0 ? sortedPersons.last?.person : nil

        // Balance por categoría
        let byCategory = calculateByCategory(expenses: expenses, exchangeRate: exchangeRate)

        return MonthlyBalance(
            totalExpensesARS: totalARS,
            totalExpensesUSD: totalUSD,
            byPerson: byPerson,
            carryOver: carryOver,
            netBalance: netBalance,
            creditor: creditor,
            debtor: debtor,
            byCategory: byCategory
        )
    }

    /// Calcula totales por categoría.
    static func calculateByCategory(
        expenses: [Expense],
        exchangeRate: Decimal
    ) -> [UUID: CategoryBalance] {
        var result: [UUID: CategoryBalance] = [:]

        // Agrupar por categoría
        let grouped = Dictionary(grouping: expenses) { $0.category?.id }

        for (categoryId, categoryExpenses) in grouped {
            guard let categoryId = categoryId,
                  let category = categoryExpenses.first?.category else { continue }

            let total = categoryExpenses.reduce(Decimal.zero) {
                $0 + $1.amountInARS(exchangeRate: exchangeRate)
            }

            var byPerson: [UUID: Decimal] = [:]
            for expense in categoryExpenses {
                guard let personId = expense.paidBy?.id else { continue }
                let amount = expense.amountInARS(exchangeRate: exchangeRate)
                byPerson[personId, default: 0] += amount
            }

            result[categoryId] = CategoryBalance(
                category: category,
                total: total,
                byPerson: byPerson
            )
        }

        return result
    }
}
