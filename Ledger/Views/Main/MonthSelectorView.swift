//
//  MonthSelectorView.swift
//  Ledger
//
//  Selector global de mes con flechas de navegación.
//

import SwiftUI

struct MonthSelectorView: View {
    @Binding var year: Int
    @Binding var month: Int

    private let calendar = Calendar.current

    private var monthName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "es_AR")
        return dateFormatter.monthSymbols[month - 1].capitalized
    }

    private var isCurrentMonth: Bool {
        let now = Date()
        return year == now.year && month == now.month
    }

    var body: some View {
        HStack(spacing: 16) {
            Button {
                goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.plain)

            VStack(spacing: 0) {
                Text(monthName)
                    .font(.headline)
                Text(String(year))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 100)

            Button {
                goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.plain)
            .opacity(isCurrentMonth ? 0.3 : 1)
            .disabled(isCurrentMonth)
        }
    }

    private func goToPreviousMonth() {
        if month == 1 {
            month = 12
            year -= 1
        } else {
            month -= 1
        }
    }

    private func goToNextMonth() {
        guard !isCurrentMonth else { return }
        if month == 12 {
            month = 1
            year += 1
        } else {
            month += 1
        }
    }
}

#Preview {
    @Previewable @State var year = 2025
    @Previewable @State var month = 12
    MonthSelectorView(year: $year, month: $month)
}
