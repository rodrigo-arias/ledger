//
//  Date+Extensions.swift
//  Ledger
//

import Foundation

extension Date {
    /// Año de la fecha.
    var year: Int {
        Calendar.current.component(.year, from: self)
    }

    /// Mes de la fecha (1-12).
    var month: Int {
        Calendar.current.component(.month, from: self)
    }

    /// Tupla (año, mes) para agrupar y buscar.
    var yearMonth: (year: Int, month: Int) {
        (year, month)
    }

    /// Nombre del mes en español.
    var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_AR")
        formatter.dateFormat = "MMMM"
        return formatter.string(from: self).capitalized
    }

    /// Nombre corto del mes (3 letras).
    var monthNameShort: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_AR")
        formatter.dateFormat = "MMM"
        return formatter.string(from: self).uppercased()
    }

    /// Formato corto: "15 Dic"
    var shortFormat: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_AR")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: self)
    }

    /// Formato medio: "15 de Diciembre"
    var mediumFormat: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_AR")
        formatter.dateFormat = "d 'de' MMMM"
        return formatter.string(from: self)
    }

    /// Formato con año: "Diciembre 2025"
    var monthYearFormat: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_AR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self).capitalized
    }

    /// Primer día del mes actual.
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    /// Último día del mes actual.
    var endOfMonth: Date {
        let calendar = Calendar.current
        guard let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return self
        }
        return calendar.date(byAdding: .day, value: -1, to: startOfNextMonth) ?? self
    }

    /// Crea una fecha para un año y mes específicos (día 1).
    static func from(year: Int, month: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        return Calendar.current.date(from: components)
    }
}
