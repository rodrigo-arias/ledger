//
//  MonthCloseView.swift
//  Ledger
//
//  Vista para cerrar un mes registrando pagos del deudor al acreedor.
//

import SwiftData
import SwiftUI

struct MonthCloseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let household: Household
    let year: Int
    let month: Int
    let totalBalance: Decimal
    let exchangeRate: Decimal

    @State private var monthlyClose: MonthlyClose?
    @State private var showingPaymentForm = false
    @State private var editingPayment: Payment?

    @Query(sort: \MonthlyClose.closedAt, order: .reverse)
    private var allCloses: [MonthlyClose]

    @Query(sort: \Payment.date)
    private var allPayments: [Payment]

    private var existingClose: MonthlyClose? {
        allCloses.first {
            $0.household?.id == household.id &&
                $0.year == year &&
                $0.month == month
        }
    }

    private var payments: [Payment] {
        allPayments.filter { $0.monthlyClose?.id == monthlyClose?.id }
    }

    private var totalPaidARS: Decimal {
        payments.reduce(Decimal.zero) { $0 + $1.amountInARS(exchangeRate: exchangeRate) }
    }

    private var remainingARS: Decimal {
        abs(totalBalance) - totalPaidARS
    }

    private var canClose: Bool {
        remainingARS <= 0 && !payments.isEmpty
    }

    private var isClosed: Bool {
        monthlyClose?.isClosed ?? false
    }

    private var personsByName: [Person] {
        household.members.sorted { $0.name < $1.name }
    }

    private var debtor: Person? {
        totalBalance > 0 ? personsByName.first : personsByName.last
    }

    private var creditor: Person? {
        totalBalance > 0 ? personsByName.last : personsByName.first
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_AR")
        return formatter.monthSymbols[month - 1].capitalized
    }

    var body: some View {
        NavigationStack {
            Form {
                balanceSection
                paymentsSection
                statusSection
            }
            .navigationTitle("\(monthName) \(year)")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Listo") { dismiss() }
                    }
                }
                .onAppear { loadOrCreateClose() }
                .sheet(isPresented: $showingPaymentForm) {
                    PaymentFormView(
                        payment: editingPayment,
                        remainingARS: remainingARS,
                        exchangeRate: exchangeRate,
                        onSave: { amount, currency, date in
                            savePayment(amount: amount, currency: currency, date: date)
                        },
                        onDelete: editingPayment != nil ? {
                            if let payment = editingPayment {
                                modelContext.delete(payment)
                            }
                            editingPayment = nil
                        } : nil
                    )
                }
        }
    }

    // MARK: - Sections

    private var balanceSection: some View {
        Section("Balance") {
            if let debtor, let creditor {
                LabeledContent("\(debtor.name) debe a \(creditor.name)") {
                    Text(abs(totalBalance).formatted(currency: .ars))
                }

                if totalPaidARS > 0 {
                    LabeledContent("Pagado") {
                        Text(totalPaidARS.formatted(currency: .ars))
                            .foregroundStyle(.green)
                    }

                    LabeledContent("Pendiente") {
                        Text(remainingARS.formatted(currency: .ars))
                            .fontWeight(.semibold)
                            .foregroundStyle(remainingARS <= 0 ? .green : .orange)
                    }
                }
            }
        }
    }

    private var paymentsSection: some View {
        Section("Pagos") {
            paymentsContent
        }
    }

    @ViewBuilder
    private var paymentsContent: some View {
        if payments.isEmpty {
            Text("Sin pagos registrados")
                .foregroundStyle(.secondary)
        } else {
            ForEach(payments) { payment in
                PaymentRow(payment: payment, exchangeRate: exchangeRate)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !isClosed {
                            editingPayment = payment
                            showingPaymentForm = true
                        }
                    }
            }
            .onDelete { offsets in
                if !isClosed {
                    deletePayments(at: offsets)
                }
            }
        }

        if !isClosed {
            Button {
                editingPayment = nil
                showingPaymentForm = true
            } label: {
                Label("Agregar pago", systemImage: "plus")
            }
        }
    }

    private var statusSection: some View {
        Section {
            if isClosed {
                Button {
                    reopenMonth()
                } label: {
                    HStack {
                        Spacer()
                        Text("Reabrir mes")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            } else {
                Button { closeMonth() } label: {
                    HStack {
                        Spacer()
                        Text("Cerrar mes")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!canClose)
            }
        }
    }

    // MARK: - Actions

    private func loadOrCreateClose() {
        if let existing = existingClose {
            monthlyClose = existing
        } else {
            let close = MonthlyClose(
                year: year,
                month: month,
                totalExpensesARS: 0,
                carryOverFromPrevious: 0,
                balanceAtClose: totalBalance,
                exchangeRateUsed: exchangeRate
            )
            close.isClosed = false
            close.household = household
            modelContext.insert(close)
            monthlyClose = close
        }
    }

    private func savePayment(amount: Decimal, currency: Currency, date: Date) {
        if let existing = editingPayment {
            existing.amount = amount
            existing.currency = currency
            existing.date = date
        } else {
            let payment = Payment(amount: amount, currency: currency, date: date)
            payment.monthlyClose = monthlyClose
            modelContext.insert(payment)
        }
        editingPayment = nil
    }

    private func deletePayments(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(payments[index])
        }
    }

    private func closeMonth() {
        guard let close = monthlyClose else { return }
        close.isClosed = true
        close.closedAt = Date()
        close.balanceAtClose = totalBalance
        close.exchangeRateUsed = exchangeRate
        dismiss()
    }

    private func reopenMonth() {
        monthlyClose?.isClosed = false
    }
}

// MARK: - Payment Row

struct PaymentRow: View {
    let payment: Payment
    let exchangeRate: Decimal

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(payment.amount.formatted(currency: payment.currency))
                    .fontWeight(.medium)
                if payment.currency == .usd {
                    Text("≈ \(payment.amountInARS(exchangeRate: exchangeRate).formatted(currency: .ars))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(payment.date, style: .date)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    MonthCloseView(
        household: SampleData.household,
        year: 2_025,
        month: 12,
        totalBalance: 500_000,
        exchangeRate: 1_410
    )
    .modelContainer(SampleData.container)
}
