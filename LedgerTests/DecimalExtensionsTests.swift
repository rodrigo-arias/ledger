//
//  DecimalExtensionsTests.swift
//  LedgerTests
//

@testable import Ledger
import XCTest

final class DecimalExtensionsTests: XCTestCase {

    // MARK: - formatted(currency:)

    func testFormattedCurrency_ARS_withThousandsSeparator() {
        let amount: Decimal = 45_000
        let result = amount.formatted(currency: .ars)
        XCTAssertEqual(result, "$45.000")
    }

    func testFormattedCurrency_USD() {
        let amount: Decimal = 100
        let result = amount.formatted(currency: .usd)
        XCTAssertEqual(result, "US$100")
    }

    func testFormattedCurrency_withDecimals() {
        let amount: Decimal = 1_234.56
        let result = amount.formatted(currency: .ars, showDecimals: true)
        XCTAssertEqual(result, "$1.234,56")
    }

    func testFormattedCurrency_largeAmount() {
        let amount: Decimal = 1_234_567
        let result = amount.formatted(currency: .ars)
        XCTAssertEqual(result, "$1.234.567")
    }

    // MARK: - formattedAmount

    func testFormattedAmount_noDecimals() {
        let amount: Decimal = 45_000
        let result = amount.formattedAmount()
        XCTAssertEqual(result, "45.000")
    }

    func testFormattedAmount_withDecimals() {
        let amount: Decimal = 1_234.56
        let result = amount.formattedAmount(showDecimals: true)
        XCTAssertEqual(result, "1.234,56")
    }

    // MARK: - formattedPercentage

    func testFormattedPercentage_wholeNumber() {
        let percent: Decimal = 0.78
        let result = percent.formattedPercentage()
        XCTAssertEqual(result, "78%")
    }

    func testFormattedPercentage_withDecimal() {
        let percent: Decimal = 0.785
        let result = percent.formattedPercentage()
        XCTAssertEqual(result, "78,5%")
    }

    func testFormattedPercentage_zero() {
        let percent: Decimal = 0
        let result = percent.formattedPercentage()
        XCTAssertEqual(result, "0%")
    }

    func testFormattedPercentage_oneHundred() {
        let percent: Decimal = 1
        let result = percent.formattedPercentage()
        XCTAssertEqual(result, "100%")
    }
}
