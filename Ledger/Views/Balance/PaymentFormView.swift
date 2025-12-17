//
//  PaymentFormView.swift
//  Ledger
//
//  Formulario para agregar o editar un pago.
//

import SwiftUI

struct PaymentFormView: View {
    @Environment(\.dismiss) private var dismiss

    let payment: Payment?
    let remainingARS: Decimal
    let exchangeRate: Decimal
    let onSave: (Decimal, Currency, Date) -> Void
    var onDelete: (() -> Void)?

    @State private var amountText = ""
    @State private var currency: Currency = .ars
    @State private var date = Date()

    private var isEditing: Bool {
        payment != nil
    }

    private var parsedAmount: Decimal? {
        Formatters.parseAmount(amountText)
    }

    private var isValid: Bool {
        parsedAmount != nil && parsedAmount! > 0
    }

    private var equivalentARS: Decimal? {
        guard let amount = parsedAmount, currency == .usd else { return nil }
        return amount * exchangeRate
    }

    private var remainingAfterPayment: Decimal {
        guard let amount = parsedAmount else { return remainingARS }
        let paymentARS = currency == .usd ? amount * exchangeRate : amount
        return remainingARS - paymentARS
    }

    private var remainingInUSD: Decimal {
        CurrencyConverter.toUSD(amountARS: remainingARS, exchangeRate: exchangeRate)
    }

    var body: some View {
        NavigationStack {
            Form {
                if !isEditing, remainingARS > 0, amountText.isEmpty {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Button {
                                    currency = .ars
                                    amountText = remainingARS.formattedAmount()
                                } label: {
                                    Text(remainingARS.formatted(currency: .ars))
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.accentColor.opacity(0.1))
                                        .foregroundStyle(Color.accentColor)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)

                                Button {
                                    currency = .usd
                                    amountText = remainingInUSD.formattedAmount()
                                } label: {
                                    Text(remainingInUSD.formatted(currency: .usd))
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.accentColor.opacity(0.1))
                                        .foregroundStyle(Color.accentColor)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Pendiente")
                    }
                }

                Section {
                    HStack {
                        Picker("Moneda", selection: $currency) {
                            ForEach(Currency.allCases) { curr in
                                Text(curr.rawValue).tag(curr)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)

                        TextField("Monto", text: $amountText)
                            .numericKeyboard()
                            .trailingAlignment()
                            .onChange(of: amountText) { _, newValue in
                                amountText = Formatters.formatAmountInput(newValue)
                            }
                    }

                    if let equivalent = equivalentARS {
                        LabeledContent("En ARS") {
                            Text(equivalent.formatted(currency: .ars))
                                .foregroundStyle(.secondary)
                        }
                    }

                    DatePicker("Fecha", selection: $date, displayedComponents: .date)
                }

                if !isEditing, parsedAmount != nil {
                    Section {
                        LabeledContent("Resto después de este pago") {
                            Text(remainingAfterPayment.formatted(currency: .ars))
                                .fontWeight(.medium)
                                .foregroundStyle(remainingAfterPayment <= 0 ? .green : .primary)
                        }
                    }
                }

                if isEditing, onDelete != nil {
                    Section {
                        Button(role: .destructive) {
                            onDelete?()
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Eliminar pago")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Editar pago" : "Nuevo pago")
            #if os(iOS)
                .inlineNavigationTitle()
            #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Guardar") {
                            if let amount = parsedAmount {
                                onSave(amount, currency, date)
                                dismiss()
                            }
                        }
                        .disabled(!isValid)
                    }
                }
                .onAppear {
                    if let payment {
                        amountText = payment.amount.formattedAmount()
                        currency = payment.currency
                        date = payment.date
                    }
                }
        }
    }
}

#Preview("Nuevo") {
    PaymentFormView(payment: nil, remainingARS: 500_000, exchangeRate: 1_410) { _, _, _ in }
}

#Preview("Editar") {
    PaymentFormView(
        payment: Payment(amount: 200, currency: .usd),
        remainingARS: 218_000,
        exchangeRate: 1_410
    ) { _, _, _ in }
}
