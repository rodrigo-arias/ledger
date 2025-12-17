//
//  MonthlyConfigView.swift
//  Ledger
//
//  Vista para configurar el tipo de cambio e ingresos del mes.
//

import SwiftData
import SwiftUI

struct MonthlyConfigView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let household: Household
    let year: Int
    let month: Int

    @State private var exchangeRateText = ""
    @State private var income1Text = ""
    @State private var income2Text = ""
    @State private var isEditing = false
    @State private var fixedExpensesDebtorId: UUID?

    private var members: [Person] {
        household.members.sorted { ($0.isCurrentUser ? 0 : 1) < ($1.isCurrentUser ? 0 : 1) }
    }

    private var person1: Person? { members.first }
    private var person2: Person? { members.dropFirst().first }

    private var monthName: String {
        Date.from(year: year, month: month)?.monthYearFormat ?? "\(month)/\(year)"
    }

    // MARK: - Valores del mes anterior

    private var previousMonthConfigs: [MonthlyConfig] {
        let prevMonth = month == 1 ? 12 : month - 1
        let prevYear = month == 1 ? year - 1 : year
        return household.monthlyConfigs.filter { $0.year == prevYear && $0.month == prevMonth }
    }

    private var previousExchangeRate: Decimal? {
        previousMonthConfigs.first?.exchangeRate
    }

    private func previousIncome(for person: Person?) -> Decimal? {
        guard let person else { return nil }
        return previousMonthConfigs.first { $0.person?.id == person.id }?.incomeUSD
    }

    // MARK: - Validación

    private var parsedExchangeRate: Decimal? {
        guard let value = Formatters.parseAmount(exchangeRateText), value > 0 else { return nil }
        return value
    }

    private var parsedIncome1: Decimal? {
        guard let value = Formatters.parseAmount(income1Text), value >= 0 else { return nil }
        return value
    }

    private var parsedIncome2: Decimal? {
        guard let value = Formatters.parseAmount(income2Text), value >= 0 else { return nil }
        return value
    }

    private var isValid: Bool {
        parsedExchangeRate != nil && parsedIncome1 != nil && parsedIncome2 != nil
    }

    // MARK: - Porcentajes (redondeados)

    private var percentage1: Int? {
        guard let i1 = parsedIncome1, let i2 = parsedIncome2, i1 + i2 > 0 else { return nil }
        let pct = (i1 / (i1 + i2)) * 100
        return Int(round(Double(truncating: pct as NSNumber)))
    }

    private var percentage2: Int? {
        guard let pct1 = percentage1 else { return nil }
        return 100 - pct1
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Dólar") {
                    HStack {
                        Text("Tipo de cambio")
                        Spacer()
                        TextField("Requerido", text: $exchangeRateText)
                            .multilineTextAlignment(.trailing)
                            .numericKeyboard()
                            .frame(maxWidth: 120)
                            .onChange(of: exchangeRateText) { _, newValue in
                                exchangeRateText = Formatters.formatAmountInput(newValue)
                            }
                    }
                }

                Section {
                    if let person1 {
                        HStack {
                            Text(person1.name)
                            Spacer()
                            Text("US$")
                                .foregroundStyle(.secondary)
                            TextField("Requerido", text: $income1Text)
                                .multilineTextAlignment(.trailing)
                                .numericKeyboard()
                                .frame(maxWidth: 100)
                                .onChange(of: income1Text) { _, newValue in
                                    income1Text = Formatters.formatAmountInput(newValue)
                                }
                        }
                    }

                    if let person2 {
                        HStack {
                            Text(person2.name)
                            Spacer()
                            Text("US$")
                                .foregroundStyle(.secondary)
                            TextField("Requerido", text: $income2Text)
                                .multilineTextAlignment(.trailing)
                                .numericKeyboard()
                                .frame(maxWidth: 100)
                                .onChange(of: income2Text) { _, newValue in
                                    income2Text = Formatters.formatAmountInput(newValue)
                                }
                        }
                    }
                } header: {
                    Text("Ingresos mensuales")
                } footer: {
                    if let pct1 = percentage1, let pct2 = percentage2,
                       let p1 = person1, let p2 = person2
                    {
                        Text("\(p1.name) aporta \(pct1)% • \(p2.name) aporta \(pct2)%")
                    }
                }

                Section {
                    Picker("Debe gastos fijos", selection: $fixedExpensesDebtorId) {
                        Text("Nadie").tag(nil as UUID?)
                        ForEach(household.members) { person in
                            Text(person.name).tag(person.id as UUID?)
                        }
                    }
                } footer: {
                    Text("La persona seleccionada debe el monto de gastos fijos del mes")
                }
            }
            .navigationTitle(monthName)
            #if os(iOS)
                .inlineNavigationTitle()
            #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(isEditing ? "Actualizar" : "Guardar") {
                            saveConfig()
                            dismiss()
                        }
                        .disabled(!isValid)
                    }
                }
                .onAppear { loadConfig() }
        }
    }

    // MARK: - Data

    private func loadConfig() {
        let existingConfigs = household.monthlyConfigs.filter { $0.year == year && $0.month == month }

        if let first = existingConfigs.first {
            isEditing = true
            exchangeRateText = first.exchangeRate.formattedAmount()
            fixedExpensesDebtorId = first.fixedExpensesDebtorId

            if let config1 = existingConfigs.first(where: { $0.person?.id == person1?.id }) {
                income1Text = config1.incomeUSD.formattedAmount()
            }
            if let config2 = existingConfigs.first(where: { $0.person?.id == person2?.id }) {
                income2Text = config2.incomeUSD.formattedAmount()
            }
        } else {
            if let prevTC = previousExchangeRate {
                exchangeRateText = prevTC.formattedAmount()
            }
            if let prevIncome1 = previousIncome(for: person1) {
                income1Text = prevIncome1.formattedAmount()
            }
            if let prevIncome2 = previousIncome(for: person2) {
                income2Text = prevIncome2.formattedAmount()
            }
            // Default: persona que gana más
            if let i1 = parsedIncome1, let i2 = parsedIncome2 {
                fixedExpensesDebtorId = i1 >= i2 ? person1?.id : person2?.id
            }
        }
    }

    private func saveConfig() {
        guard let tc = parsedExchangeRate,
              let i1 = parsedIncome1,
              let i2 = parsedIncome2
        else { return }

        let existingConfigs = household.monthlyConfigs.filter { $0.year == year && $0.month == month }
        for config in existingConfigs {
            modelContext.delete(config)
        }

        if let person1 {
            let config1 = MonthlyConfig(year: year, month: month, exchangeRate: tc, incomeUSD: i1, fixedExpensesDebtorId: fixedExpensesDebtorId)
            config1.person = person1
            config1.household = household
            modelContext.insert(config1)
        }

        if let person2 {
            let config2 = MonthlyConfig(year: year, month: month, exchangeRate: tc, incomeUSD: i2, fixedExpensesDebtorId: fixedExpensesDebtorId)
            config2.person = person2
            config2.household = household
            modelContext.insert(config2)
        }
    }
}

#Preview {
    MonthlyConfigView(
        household: SampleData.household,
        year: 2_025,
        month: 12
    )
    .modelContainer(SampleData.container)
}
