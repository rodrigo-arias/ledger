//
//  ExpenseRowView.swift
//  Ledger
//
//  Fila individual que muestra un gasto en la lista.
//

import SwiftData
import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense
    var exchangeRate: Decimal = 1

    var body: some View {
        HStack {
            // Emoji de categoría
            if let emoji = expense.category?.emoji {
                Text(emoji)
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.concept)
                    .font(.body)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let paidBy = expense.paidBy {
                        Text(paidBy.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if expense.hasSpecificDate, let date = expense.date {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(date.shortFormat)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(expense.amount.formatted(currency: expense.currency))
                    .font(.body)
                    .fontWeight(.medium)

                // Si es USD, mostrar equivalente en ARS
                if expense.currency == .usd, exchangeRate > 0 {
                    let arsAmount = expense.amountInARS(exchangeRate: exchangeRate)
                    Text(arsAmount.formatted(currency: .ars))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        ExpenseRowView(
            expense: SampleData.sampleExpense,
            exchangeRate: 1_400
        )
    }
    .modelContainer(SampleData.container)
}
