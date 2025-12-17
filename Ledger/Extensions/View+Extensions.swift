//
//  View+Extensions.swift
//  Ledger
//
//  Extensiones para compatibilidad cross-platform.
//

import SwiftUI

extension View {
    /// Aplica keyboardType solo en iOS (no existe en macOS).
    @ViewBuilder
    func numericKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.decimalPad)
        #else
        self
        #endif
    }

    /// Aplica textAlignment solo donde está disponible.
    @ViewBuilder
    func trailingAlignment() -> some View {
        multilineTextAlignment(.trailing)
    }
}
