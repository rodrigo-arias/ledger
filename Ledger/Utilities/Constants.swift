//
//  Constants.swift
//  Ledger
//

import Foundation

enum Currency: String, Codable, CaseIterable, Identifiable {
    case ars = "ARS"
    case usd = "USD"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .ars: "$"
        case .usd: "US$"
        }
    }

    var name: String {
        switch self {
        case .ars: "Pesos Argentinos"
        case .usd: "Dólares"
        }
    }
}
