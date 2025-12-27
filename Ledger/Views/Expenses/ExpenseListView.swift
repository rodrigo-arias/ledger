//
//  ExpenseListView.swift
//  Ledger
//
//  Lista de gastos con filtros y ordenamiento.
//

import SwiftData
import SwiftUI

// MARK: - Filtro y ordenamiento de gastos

enum ExpenseFilter: String, CaseIterable {
    case me = "Míos"
    case other = "Otro"
    case all = "Todos"
}

enum ExpenseSort: String, CaseIterable {
    case byDate = "Por fecha"
    case byCategory = "Por categoría"
}

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext

    let household: Household
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int

    @Query(sort: \Expense.createdAt, order: .reverse)
    private var allExpenses: [Expense]

    @State private var showingAddExpense = false
    @State private var showingMonthConfig = false
    @State private var selectedExpense: Expense?
    @State private var expenseFilter: ExpenseFilter = .me
    @State private var expenseSort: ExpenseSort = .byDate

    private var currentUser: Person? {
        (household.members ?? []).first { $0.isCurrentUser }
    }

    private var otherUser: Person? {
        (household.members ?? []).first { !$0.isCurrentUser }
    }

    private var expenses: [Expense] {
        let householdExpenses = allExpenses.filter { expense in
            guard expense.household?.id == household.id else { return false }
            let (year, month) = expense.yearMonth
            return year == selectedYear && month == selectedMonth
        }

        switch expenseFilter {
        case .me:
            return householdExpenses.filter { $0.paidBy?.id == currentUser?.id }
        case .other:
            return householdExpenses.filter { $0.paidBy?.id == otherUser?.id }
        case .all:
            return householdExpenses
        }
    }

    private var groupedExpenses: [(key: String, expenses: [Expense])] {
        switch expenseSort {
        case .byDate:
            let grouped = Dictionary(grouping: expenses) { expense in
                (expense.date ?? expense.createdAt).monthYearFormat
            }
            return grouped.map { (key: $0.key, expenses: $0.value) }
                .sorted {
                    let date1 = $0.expenses.first?.date ?? $0.expenses.first?.createdAt ?? Date()
                    let date2 = $1.expenses.first?.date ?? $1.expenses.first?.createdAt ?? Date()
                    return date1 > date2
                }
        case .byCategory:
            let grouped = Dictionary(grouping: expenses) { expense in
                expense.category?.displayName ?? "Sin categoría"
            }
            return grouped.map { (key: $0.key, expenses: $0.value) }
                .sorted { $0.key < $1.key }
        }
    }

    private var selectedMonthConfig: MonthlyConfig? {
        (household.monthlyConfigs ?? []).first {
            $0.year == selectedYear && $0.month == selectedMonth
        }
    }

    var body: some View {
        List {
            // Banner de configuración del mes
            Section {
                Button {
                    showingMonthConfig = true
                } label: {
                    HStack {
                        if let config = selectedMonthConfig {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundStyle(.green)
                            Text("TC: \(config.exchangeRate.formattedAmount())")
                            Spacer()
                            Text("Editar")
                                .foregroundStyle(.secondary)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Configurar mes")
                            Spacer()
                        }
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            // Gastos agrupados
            ForEach(groupedExpenses, id: \.key) { group in
                Section {
                    ForEach(group.expenses) { expense in
                        ExpenseRowView(
                            expense: expense,
                            exchangeRate: exchangeRateFor(expense: expense)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedExpense = expense
                        }
                    }
                    .onDelete { indexSet in
                        deleteExpenses(from: group.expenses, at: indexSet)
                    }
                } header: {
                    HStack {
                        Text(group.key)
                        Spacer()
                        Text(totalForGroup(group.expenses).formatted(currency: .ars))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if expenses.isEmpty {
                ContentUnavailableView(
                    "Sin gastos",
                    systemImage: "creditcard",
                    description: Text(emptyStateMessage)
                )
            }
        }
        .navigationTitle("Gastos")
        .toolbar {
            ToolbarItem(placement: .principal) {
                MonthSelectorView(year: $selectedYear, month: $selectedMonth)
            }

            ToolbarItem(placement: .navigation) {
                Menu {
                    Section("Filtrar por") {
                        Picker("Filtro", selection: $expenseFilter) {
                            ForEach(ExpenseFilter.allCases, id: \.self) { filter in
                                Label(filterLabel(for: filter), systemImage: filterIcon(for: filter))
                                    .tag(filter)
                            }
                        }
                    }

                    Section("Ordenar por") {
                        Picker("Ordenar", selection: $expenseSort) {
                            ForEach(ExpenseSort.allCases, id: \.self) { sort in
                                Label(sort.rawValue, systemImage: sortIcon(for: sort))
                                    .tag(sort)
                            }
                        }
                    }
                } label: {
                    Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddExpense = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(household: household)
        }
        .sheet(isPresented: $showingMonthConfig) {
            MonthlyConfigView(household: household, year: selectedYear, month: selectedMonth)
        }
        .sheet(item: $selectedExpense) { expense in
            ExpenseDetailView(expense: expense, household: household)
        }
    }

    private func exchangeRateFor(expense: Expense) -> Decimal {
        let (year, month) = expense.yearMonth
        return (household.monthlyConfigs ?? [])
            .first { $0.year == year && $0.month == month }?
            .exchangeRate ?? 1
    }

    private func totalForGroup(_ expenses: [Expense]) -> Decimal {
        expenses.reduce(Decimal.zero) { total, expense in
            let rate = exchangeRateFor(expense: expense)
            return total + expense.amountInARS(exchangeRate: rate)
        }
    }

    private func deleteExpenses(from expenses: [Expense], at indexSet: IndexSet) {
        for index in indexSet {
            let expense = expenses[index]
            modelContext.delete(expense)
        }
    }

    private func filterLabel(for filter: ExpenseFilter) -> String {
        switch filter {
        case .me:
            currentUser?.name ?? "Míos"
        case .other:
            otherUser?.name ?? "Otro"
        case .all:
            "Todos"
        }
    }

    private func filterIcon(for filter: ExpenseFilter) -> String {
        switch filter {
        case .me:
            "person.fill"
        case .other:
            "person"
        case .all:
            "person.2"
        }
    }

    private func sortIcon(for sort: ExpenseSort) -> String {
        switch sort {
        case .byDate:
            "calendar"
        case .byCategory:
            "folder"
        }
    }

    private var hasActiveFilters: Bool {
        expenseFilter != .all || expenseSort != .byDate
    }

    private var emptyStateMessage: String {
        switch expenseFilter {
        case .me:
            "No tenés gastos registrados"
        case .other:
            "\(otherUser?.name ?? "La otra persona") no tiene gastos"
        case .all:
            "Agregá tu primer gasto tocando +"
        }
    }
}

#Preview {
    @Previewable @State var year = Date().year
    @Previewable @State var month = Date().month
    NavigationStack {
        ExpenseListView(
            household: SampleData.household,
            selectedYear: $year,
            selectedMonth: $month
        )
    }
    .modelContainer(SampleData.container)
}
