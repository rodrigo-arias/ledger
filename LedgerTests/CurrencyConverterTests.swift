//
//  CurrencyConverterTests.swift
//  LedgerTests
//

import XCTest
@testable import Ledger

final class CurrencyConverterTests: XCTestCase {

    // MARK: - toARS

    func testToARS_withARS_returnsSameAmount() {
        let amount: Decimal = 1000
        let result = CurrencyConverter.toARS(amount: amount, currency: .ars, exchangeRate: 1400)
        XCTAssertEqual(result, 1000)
    }

    func testToARS_withUSD_convertsUsingExchangeRate() {
        let amount: Decimal = 100
        let result = CurrencyConverter.toARS(amount: amount, currency: .usd, exchangeRate: 1400)
        XCTAssertEqual(result, 140_000)
    }

    func testToARS_withZeroAmount_returnsZero() {
        let result = CurrencyConverter.toARS(amount: 0, currency: .usd, exchangeRate: 1400)
        XCTAssertEqual(result, 0)
    }

    // MARK: - toUSD

    func testToUSD_convertsARStoUSD() {
        let result = CurrencyConverter.toUSD(amountARS: 140_000, exchangeRate: 1400)
        XCTAssertEqual(result, 100)
    }

    func testToUSD_withZeroExchangeRate_returnsZero() {
        let result = CurrencyConverter.toUSD(amountARS: 140_000, exchangeRate: 0)
        XCTAssertEqual(result, 0)
    }

    func testToUSD_withZeroAmount_returnsZero() {
        let result = CurrencyConverter.toUSD(amountARS: 0, exchangeRate: 1400)
        XCTAssertEqual(result, 0)
    }

    // MARK: - paymentTotalInARS

    func testPaymentTotalInARS_withOnlyARS() {
        let result = CurrencyConverter.paymentTotalInARS(amountARS: 50_000, amountUSD: nil, exchangeRate: 1400)
        XCTAssertEqual(result, 50_000)
    }

    func testPaymentTotalInARS_withOnlyUSD() {
        let result = CurrencyConverter.paymentTotalInARS(amountARS: nil, amountUSD: 100, exchangeRate: 1400)
        XCTAssertEqual(result, 140_000)
    }

    func testPaymentTotalInARS_withBothCurrencies() {
        let result = CurrencyConverter.paymentTotalInARS(amountARS: 50_000, amountUSD: 100, exchangeRate: 1400)
        XCTAssertEqual(result, 190_000)
    }

    func testPaymentTotalInARS_withNilAmounts_returnsZero() {
        let result = CurrencyConverter.paymentTotalInARS(amountARS: nil, amountUSD: nil, exchangeRate: 1400)
        XCTAssertEqual(result, 0)
    }
}
