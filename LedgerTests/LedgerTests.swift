//
//  LedgerTests.swift
//  LedgerTests
//

import XCTest
@testable import Ledger

final class LedgerTests: XCTestCase {

    func testCurrencySymbol_ARS() {
        XCTAssertEqual(Currency.ars.symbol, "$")
    }

    func testCurrencySymbol_USD() {
        XCTAssertEqual(Currency.usd.symbol, "US$")
    }
}
