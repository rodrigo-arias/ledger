//
//  BalanceCalculatorTests.swift
//  LedgerTests
//

import XCTest
import SwiftData
@testable import Ledger

@MainActor
final class BalanceCalculatorTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        let schema = Schema([
            Household.self,
            Person.self,
            Category.self,
            MonthlyConfig.self,
            Expense.self,
            Payment.self,
            MonthlyClose.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = container.mainContext
    }

    override func tearDown() async throws {
        container = nil
        context = nil
    }

    // MARK: - Basic Balance Calculation

    func testCalculate_equalIncome_splitsFairly() throws {
        // Setup: Two people with equal income
        let household = Household(name: "Test")
        let person1 = Person(name: "Person1", isCurrentUser: true)
        let person2 = Person(name: "Person2", isCurrentUser: false)
        person1.household = household
        person2.household = household

        let config1 = MonthlyConfig(year: 2025, month: 12, exchangeRate: 1000, incomeUSD: 1000, fixedExpensesDebtorId: nil)
        config1.person = person1
        let config2 = MonthlyConfig(year: 2025, month: 12, exchangeRate: 1000, incomeUSD: 1000, fixedExpensesDebtorId: nil)
        config2.person = person2

        // Person1 pays $10,000 ARS
        let expense1 = Expense(amount: 10_000, currency: .ars, concept: "Test expense")
        expense1.paidBy = person1

        context.insert(household)

        // Calculate
        let result = BalanceCalculator.calculate(
            expenses: [expense1],
            configs: [config1, config2],
            previousClose: nil,
            exchangeRate: 1000
        )

        // Assert
        XCTAssertEqual(result.totalExpensesARS, 10_000)

        let balance1 = result.byPerson[person1.id]
        let balance2 = result.byPerson[person2.id]

        // Each should contribute 50%
        XCTAssertEqual(balance1?.contributionPercent, 0.5)
        XCTAssertEqual(balance2?.contributionPercent, 0.5)

        // Person1 paid 10,000, expected 5,000 -> difference +5,000
        XCTAssertEqual(balance1?.paid, 10_000)
        XCTAssertEqual(balance1?.expected, 5_000)
        XCTAssertEqual(balance1?.difference, 5_000)

        // Person2 paid 0, expected 5,000 -> difference -5,000
        XCTAssertEqual(balance2?.paid, 0)
        XCTAssertEqual(balance2?.expected, 5_000)
        XCTAssertEqual(balance2?.difference, -5_000)
    }

    func testCalculate_unequalIncome_weightedSplit() throws {
        let household = Household(name: "Test")
        let person1 = Person(name: "HighEarner", isCurrentUser: true)
        let person2 = Person(name: "LowEarner", isCurrentUser: false)
        person1.household = household
        person2.household = household

        // Person1 earns 75%, Person2 earns 25%
        let config1 = MonthlyConfig(year: 2025, month: 12, exchangeRate: 1000, incomeUSD: 3000, fixedExpensesDebtorId: nil)
        config1.person = person1
        let config2 = MonthlyConfig(year: 2025, month: 12, exchangeRate: 1000, incomeUSD: 1000, fixedExpensesDebtorId: nil)
        config2.person = person2

        let expense = Expense(amount: 10_000, currency: .ars, concept: "Shared expense")
        expense.paidBy = person1

        context.insert(household)

        let result = BalanceCalculator.calculate(
            expenses: [expense],
            configs: [config1, config2],
            previousClose: nil,
            exchangeRate: 1000
        )

        let balance1 = result.byPerson[person1.id]
        let balance2 = result.byPerson[person2.id]

        // Person1: 75%, Person2: 25%
        XCTAssertEqual(balance1?.contributionPercent, 0.75)
        XCTAssertEqual(balance2?.contributionPercent, 0.25)

        // Person1: paid 10,000, expected 7,500 -> diff +2,500
        XCTAssertEqual(balance1?.expected, 7_500)
        XCTAssertEqual(balance1?.difference, 2_500)

        // Person2: paid 0, expected 2,500 -> diff -2,500
        XCTAssertEqual(balance2?.expected, 2_500)
        XCTAssertEqual(balance2?.difference, -2_500)
    }

    func testCalculate_withUSDExpense_convertsCorrectly() throws {
        let household = Household(name: "Test")
        let person1 = Person(name: "Person1", isCurrentUser: true)
        person1.household = household

        let config1 = MonthlyConfig(year: 2025, month: 12, exchangeRate: 1400, incomeUSD: 1000, fixedExpensesDebtorId: nil)
        config1.person = person1

        // $100 USD at 1400 exchange rate = 140,000 ARS
        let expense = Expense(amount: 100, currency: .usd, concept: "USD expense")
        expense.paidBy = person1

        context.insert(household)

        let result = BalanceCalculator.calculate(
            expenses: [expense],
            configs: [config1],
            previousClose: nil,
            exchangeRate: 1400
        )

        XCTAssertEqual(result.totalExpensesARS, 140_000)
        XCTAssertEqual(result.totalExpensesUSD, 100)
    }

    func testCalculate_withCarryOver_addsToBalance() throws {
        let household = Household(name: "Test")
        let person1 = Person(name: "Person1", isCurrentUser: true)
        let person2 = Person(name: "Person2", isCurrentUser: false)
        person1.household = household
        person2.household = household

        let config1 = MonthlyConfig(year: 2025, month: 12, exchangeRate: 1000, incomeUSD: 1000, fixedExpensesDebtorId: nil)
        config1.person = person1
        let config2 = MonthlyConfig(year: 2025, month: 12, exchangeRate: 1000, incomeUSD: 1000, fixedExpensesDebtorId: nil)
        config2.person = person2

        let expense = Expense(amount: 10_000, currency: .ars, concept: "Test")
        expense.paidBy = person1

        // Previous month had balance of 5,000 (Person1 was owed)
        let previousClose = MonthlyClose(
            year: 2025,
            month: 11,
            totalExpensesARS: 20_000,
            carryOverFromPrevious: 0,
            balanceAtClose: 5_000,
            exchangeRateUsed: 1000
        )
        previousClose.household = household

        context.insert(household)

        let result = BalanceCalculator.calculate(
            expenses: [expense],
            configs: [config1, config2],
            previousClose: previousClose,
            exchangeRate: 1000
        )

        XCTAssertEqual(result.carryOver, 5_000)
        // Net balance = Person1's difference (5,000) + carryOver (5,000) = 10,000
        XCTAssertEqual(result.netBalance, 10_000)
    }

    // MARK: - Category Balance

    func testCalculateByCategory_groupsCorrectly() throws {
        let household = Household(name: "Test")
        let person1 = Person(name: "Person1", isCurrentUser: true)
        person1.household = household

        let category1 = Category(name: "Comida", emoji: "🍕", sortOrder: 0)
        let category2 = Category(name: "Servicios", emoji: "💡", sortOrder: 1)
        category1.household = household
        category2.household = household

        let expense1 = Expense(amount: 5_000, currency: .ars, concept: "Food 1")
        expense1.paidBy = person1
        expense1.category = category1

        let expense2 = Expense(amount: 3_000, currency: .ars, concept: "Food 2")
        expense2.paidBy = person1
        expense2.category = category1

        let expense3 = Expense(amount: 2_000, currency: .ars, concept: "Electric")
        expense3.paidBy = person1
        expense3.category = category2

        context.insert(household)

        let result = BalanceCalculator.calculateByCategory(
            expenses: [expense1, expense2, expense3],
            exchangeRate: 1000
        )

        XCTAssertEqual(result.count, 2)

        let foodBalance = result[category1.id]
        XCTAssertEqual(foodBalance?.total, 8_000)
        XCTAssertEqual(foodBalance?.byPerson[person1.id], 8_000)

        let servicesBalance = result[category2.id]
        XCTAssertEqual(servicesBalance?.total, 2_000)
    }

    // MARK: - Edge Cases

    func testCalculate_noExpenses_returnsZeroTotals() throws {
        let household = Household(name: "Test")
        let person1 = Person(name: "Person1", isCurrentUser: true)
        person1.household = household

        let config1 = MonthlyConfig(year: 2025, month: 12, exchangeRate: 1000, incomeUSD: 1000, fixedExpensesDebtorId: nil)
        config1.person = person1

        context.insert(household)

        let result = BalanceCalculator.calculate(
            expenses: [],
            configs: [config1],
            previousClose: nil,
            exchangeRate: 1000
        )

        XCTAssertEqual(result.totalExpensesARS, 0)
        XCTAssertEqual(result.totalExpensesUSD, 0)
    }

    func testCalculate_negativeExpense_subtractsFromTotal() throws {
        let household = Household(name: "Test")
        let person1 = Person(name: "Person1", isCurrentUser: true)
        person1.household = household

        let config1 = MonthlyConfig(year: 2025, month: 12, exchangeRate: 1000, incomeUSD: 1000, fixedExpensesDebtorId: nil)
        config1.person = person1

        let expense1 = Expense(amount: 10_000, currency: .ars, concept: "Purchase")
        expense1.paidBy = person1

        let expense2 = Expense(amount: -2_000, currency: .ars, concept: "Refund")
        expense2.paidBy = person1

        context.insert(household)

        let result = BalanceCalculator.calculate(
            expenses: [expense1, expense2],
            configs: [config1],
            previousClose: nil,
            exchangeRate: 1000
        )

        XCTAssertEqual(result.totalExpensesARS, 8_000)
    }
}
