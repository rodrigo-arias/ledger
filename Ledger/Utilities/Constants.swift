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
        case .ars: return "$"
        case .usd: return "US$"
        }
    }

    var name: String {
        switch self {
        case .ars: return "Pesos Argentinos"
        case .usd: return "Dólares"
        }
    }
}
