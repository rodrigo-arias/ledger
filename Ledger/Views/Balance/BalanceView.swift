//
//  BalanceView.swift
//  Ledger
//
//  Vista de balance mensual.
//

import SwiftUI
import SwiftData

struct BalanceView: View {
    let household: Household
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int

    @State private var showingMonthClose = false

    @Query(sort: \Expense.createdAt, order: .reverse)
    private var allExpenses: [Expense]

    @Query(sort: \MonthlyClose.closedAt, order: .reverse)
    private var allCloses: [MonthlyClose]

    @Query(sort: \Payment.date)
    private var allPayments: [Payment]

    private var monthExpenses: [Expense] {
        allExpenses.filter { expense in
            guard expense.household?.id == household.id else { return false }
            let (year, month) = expense.yearMonth
            return year == selectedYear && month == selectedMonth
        }
    }

    private var monthConfigs: [MonthlyConfig] {
        household.monthlyConfigs.filter {
            $0.year == selectedYear && $0.month == selectedMonth
        }
    }

    private var exchangeRate: Decimal {
        monthConfigs.first?.exchangeRate ?? 1
    }

    private var previousClose: MonthlyClose? {
        let (prevYear, prevMonth) = previousYearMonth
        return allCloses.first {
            $0.household?.id == household.id &&
            $0.year == prevYear &&
            $0.month == prevMonth
        }
    }

    private var previousYearMonth: (Int, Int) {
        if selectedMonth == 1 {
            return (selectedYear - 1, 12)
        } else {
            return (selectedYear, selectedMonth - 1)
        }
    }

    private var balance: MonthlyBalance {
        // Determinar el arrastre del mes anterior
        let (prevYear, prevMonth) = previousYearMonth

        // Si el mes anterior es histórico, ignorar su balance (asumir 0)
        let carryOverClose: MonthlyClose? = household.isHistoricalMonth(year: prevYear, month: prevMonth) ? nil : previousClose

        return BalanceCalculator.calculate(
            expenses: monthExpenses,
            configs: monthConfigs,
            previousClose: carryOverClose,
            exchangeRate: exchangeRate
        )
    }

    private var hasConfig: Bool {
        !monthConfigs.isEmpty
    }

    private var fixedExpenses: [Expense] {
        monthExpenses.filter { $0.isFixedExpense }
    }

    private var hasFixedExpenses: Bool {
        !fixedExpenses.isEmpty
    }

    private var totalFixedExpenses: Decimal {
        fixedExpenses.reduce(Decimal.zero) { $0 + $1.amountInARS(exchangeRate: exchangeRate) }
    }

    private var fixedExpensesDebtor: Person? {
        guard let debtorId = monthConfigs.first?.fixedExpensesDebtorId else { return nil }
        return household.members.first { $0.id == debtorId }
    }

    // Personas en orden consistente (alfabético por nombre - NO depende del usuario actual)
    private var personsByName: [Person] {
        household.members.sorted { $0.name < $1.name }
    }

    private var firstPerson: Person? {
        personsByName.first
    }

    private var secondPerson: Person? {
        personsByName.count > 1 ? personsByName[1] : nil
    }

    private var currentUser: Person? {
        household.members.first { $0.isCurrentUser }
    }

    private var isCurrentUserFirstPerson: Bool {
        currentUser?.id == firstPerson?.id
    }

    private var totalBalanceToPay: Decimal {
        let carryOver = balance.carryOver

        guard let debtorId = monthConfigs.first?.fixedExpensesDebtorId else {
            return carryOver
        }

        // Si el deudor es la primera persona, el balance se suma
        // Si el deudor es la segunda persona, el balance se resta
        if debtorId == firstPerson?.id {
            return carryOver + totalFixedExpenses
        } else {
            return carryOver - totalFixedExpenses
        }
    }

    private var isHistoricalMonth: Bool {
        household.isHistoricalMonth(year: selectedYear, month: selectedMonth)
    }

    private var currentMonthClose: MonthlyClose? {
        allCloses.first {
            $0.household?.id == household.id &&
            $0.year == selectedYear &&
            $0.month == selectedMonth
        }
    }

    private var isClosedMonth: Bool {
        currentMonthClose?.isClosed ?? false
    }

    private var totalPaidARS: Decimal {
        let closeId = currentMonthClose?.id
        let payments = allPayments.filter { $0.monthlyClose?.id == closeId }
        return payments.reduce(Decimal.zero) { $0 + $1.amountInARS(exchangeRate: exchangeRate) }
    }

    private var remainingBalance: Decimal {
        abs(totalBalanceToPay) - totalPaidARS
    }

    var body: some View {
        List {
            if !hasConfig {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Configurá el tipo de cambio e ingresos para este mes")
                            .font(.subheadline)
                    }
                }
            }

            // Resumen total
            Section("Resumen del mes") {
                LabeledContent("Total gastos") {
                    Text(balance.totalExpensesARS.formatted(currency: .ars))
                }
                LabeledContent("En USD") {
                    Text(CurrencyConverter.toUSD(amountARS: balance.totalExpensesARS, exchangeRate: exchangeRate).formatted(currency: .usd))
                        .foregroundStyle(.secondary)
                }
            }

            // Por persona
            Section("Por persona") {
                ForEach(Array(balance.byPerson.values).sorted { $0.person.name < $1.person.name }) { personBalance in
                    PersonBalanceRow(balance: personBalance)
                }
            }

            // Por categoría
            if !balance.byCategory.isEmpty {
                Section("Por categoría") {
                    ForEach(Array(balance.byCategory.values).sorted { $0.total > $1.total }) { categoryBalance in
                        CategoryBalanceRow(balance: categoryBalance)
                    }
                }
            }

            // Saldo final
            Section {
                if balance.carryOver != 0 {
                    LabeledContent("Diferencia del mes anterior") {
                        carryOverIndicator
                    }
                }
                if hasFixedExpenses, let debtor = fixedExpensesDebtor {
                    LabeledContent("Gastos fijos (\(debtor.name))") {
                        fixedExpensesIndicator
                    }
                }
                balanceContent
            } header: {
                Text("Balance")
            }
        }
        .navigationTitle("Balance")
        .toolbar {
            ToolbarItem(placement: .principal) {
                MonthSelectorView(year: $selectedYear, month: $selectedMonth)
            }
        }
        .sheet(isPresented: $showingMonthClose) {
            MonthCloseView(
                household: household,
                year: selectedYear,
                month: selectedMonth,
                totalBalance: totalBalanceToPay,
                exchangeRate: exchangeRate
            )
        }
    }

    @ViewBuilder
    private var carryOverIndicator: some View {
        // carryOver > 0 significa que la primera persona debe
        // Si soy la primera persona y carryOver > 0: debo (rojo hacia abajo)
        // Si soy la segunda persona y carryOver > 0: me deben (verde hacia arriba)
        let showDebt = isCurrentUserFirstPerson ? (balance.carryOver > 0) : (balance.carryOver < 0)

        HStack(spacing: 4) {
            Image(systemName: showDebt ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundStyle(showDebt ? .red : .green)
            Text(abs(balance.carryOver).formatted(currency: .ars))
        }
    }

    @ViewBuilder
    private var fixedExpensesIndicator: some View {
        // Si el deudor es el usuario actual: debe (rojo hacia abajo)
        // Si el deudor es otra persona: le deben (verde hacia arriba)
        let currentUserOwes = fixedExpensesDebtor?.id == currentUser?.id

        HStack(spacing: 4) {
            Image(systemName: currentUserOwes ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundStyle(currentUserOwes ? .red : .green)
            Text(totalFixedExpenses.formatted(currency: .ars))
        }
    }

    @ViewBuilder
    private var balanceContent: some View {
        if isHistoricalMonth {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.secondary)
                Text("Datos históricos")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        } else if isClosedMonth {
            Button {
                showingMonthClose = true
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Mes cerrado")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        } else if totalBalanceToPay != 0 {
            let debtorCreditor = calculateDebtorCreditor()

            if let debtor = debtorCreditor.debtor, let creditor = debtorCreditor.creditor {
                Button {
                    showingMonthClose = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(debtor.name) debe a \(creditor.name)")
                                .font(.headline)
                            if remainingBalance <= 0 {
                                Text("Pagado")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                            } else if totalPaidARS > 0 {
                                Text(remainingBalance.formatted(currency: .ars))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                            } else {
                                Text(abs(totalBalanceToPay).formatted(currency: .ars))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                            }
                        }
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                    }
                }
                .buttonStyle(.plain)
            }
        } else {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Saldado")
                    .font(.headline)
            }
        }
    }

    private func calculateDebtorCreditor() -> (debtor: Person?, creditor: Person?) {
        let secondPerson = household.members.first { $0.id != firstPerson?.id }

        if totalBalanceToPay > 0 {
            // Positivo = primera persona debe
            return (debtor: firstPerson, creditor: secondPerson)
        } else if totalBalanceToPay < 0 {
            // Negativo = segunda persona debe
            return (debtor: secondPerson, creditor: firstPerson)
        } else {
            return (debtor: nil, creditor: nil)
        }
    }
}

// MARK: - Person Balance Row

struct PersonBalanceRow: View {
    let balance: PersonBalance

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(balance.person.name)
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("Pagó")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(balance.paid.formatted(currency: .ars))
                }

                Spacer()

                VStack(alignment: .center) {
                    Text("Debería")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(balance.expected.formatted(currency: .ars))
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Diferencia")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: balance.difference >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundStyle(balance.difference >= 0 ? .green : .red)
                        Text(abs(balance.difference).formatted(currency: .ars))
                    }
                }
            }
            .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Category Balance Row

struct CategoryBalanceRow: View {
    let balance: CategoryBalance

    var body: some View {
        HStack {
            if let emoji = balance.category.emoji {
                Text(emoji)
            }
            Text(balance.category.name)
            Spacer()
            Text(balance.total.formatted(currency: .ars))
                .fontWeight(.medium)
        }
    }
}

// MARK: - Extensions

extension PersonBalance: Identifiable {
    var id: UUID { person.id }
}

extension CategoryBalance: Identifiable {
    var id: UUID { category.id }
}

#Preview {
    @Previewable @State var year = Date().year
    @Previewable @State var month = Date().month
    NavigationStack {
        BalanceView(
            household: SampleData.household,
            selectedYear: $year,
            selectedMonth: $month
        )
    }
    .modelContainer(SampleData.container)
}
