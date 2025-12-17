//
//  LedgerTests.swift
//  LedgerTests
//

@testable import Ledger
import XCTest

final class LedgerTests: XCTestCase {

    func testCurrencySymbol_ARS() {
        XCTAssertEqual(Currency.ars.symbol, "$")
    }

    func testCurrencySymbol_USD() {
        XCTAssertEqual(Currency.usd.symbol, "US$")
    }
}
