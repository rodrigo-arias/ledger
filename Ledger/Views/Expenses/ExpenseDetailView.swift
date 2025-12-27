//
//  ExpenseDetailView.swift
//  Ledger
//
//  Vista de detalle y edición de un gasto.
//

import SwiftData
import SwiftUI

struct ExpenseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var expense: Expense
    let household: Household

    @Query private var allCloses: [MonthlyClose]

    @State private var concept: String = ""
    @State private var amountText: String = ""
    @State private var currency: Currency = .ars
    @State private var hasDate: Bool = false
    @State private var date: Date = .init()
    @State private var note: String = ""
    @State private var selectedCategory: Category?
    @State private var selectedPerson: Person?
    @State private var isFixedExpense: Bool = false

    @State private var showingDeleteConfirmation = false

    private var categories: [Category] {
        (household.categories ?? []).sorted { $0.sortOrder < $1.sortOrder }
    }

    private var isMonthClosed: Bool {
        let (year, month) = expense.yearMonth
        return allCloses.contains {
            $0.household?.id == household.id &&
                $0.year == year &&
                $0.month == month &&
                $0.isClosed
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if isMonthClosed {
                    Section {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.orange)
                            Text("Este mes está cerrado. Reabrilo desde Balance para editar.")
                                .font(.subheadline)
                        }
                    }
                }

                Section {
                    TextField("Concepto", text: $concept)
                        .disabled(isMonthClosed)

                    HStack {
                        Picker("Moneda", selection: $currency) {
                            ForEach(Currency.allCases) { curr in
                                Text(curr.rawValue).tag(curr)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                        .disabled(isMonthClosed)

                        TextField("Monto", text: $amountText)
                            .numericKeyboard()
                            .trailingAlignment()
                            .disabled(isMonthClosed)
                            .onChange(of: amountText) { _, newValue in
                                amountText = Formatters.formatAmountInput(newValue)
                            }
                    }
                }

                Section {
                    Picker("Categoría", selection: $selectedCategory) {
                        Text("Sin categoría").tag(nil as Category?)
                        ForEach(categories) { category in
                            Text(category.displayName).tag(category as Category?)
                        }
                    }
                    .disabled(isMonthClosed)

                    Picker("Pagó", selection: $selectedPerson) {
                        Text("Seleccionar").tag(nil as Person?)
                        ForEach(household.members ?? []) { person in
                            Text(person.name).tag(person as Person?)
                        }
                    }
                    .disabled(isMonthClosed)

                    Toggle("Gasto fijo", isOn: $isFixedExpense)
                        .disabled(isMonthClosed)

                    Toggle("Agregar fecha", isOn: $hasDate)
                        .disabled(isMonthClosed)

                    if hasDate {
                        DatePicker("Fecha", selection: $date, displayedComponents: .date)
                            .disabled(isMonthClosed)
                    }
                }

                Section {
                    TextField("Nota (opcional)", text: $note, axis: .vertical)
                        .lineLimit(2 ... 4)
                        .disabled(isMonthClosed)
                }

                if !isMonthClosed {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Eliminar gasto")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Editar Gasto")
            #if os(iOS)
                .inlineNavigationTitle()
            #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Guardar") {
                            saveChanges()
                            dismiss()
                        }
                        .disabled(!isValid || isMonthClosed)
                    }
                }
                .onAppear {
                    loadExpense()
                }
                .confirmationDialog(
                    "¿Eliminar este gasto?",
                    isPresented: $showingDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Eliminar", role: .destructive) {
                        deleteExpense()
                    }
                    Button("Cancelar", role: .cancel) {}
                }
        }
    }

    private var isValid: Bool {
        !concept.trimmingCharacters(in: .whitespaces).isEmpty &&
            parsedAmount != nil &&
            parsedAmount! != 0 &&
            selectedPerson != nil
    }

    private var parsedAmount: Decimal? {
        Formatters.parseAmount(amountText)
    }

    private func loadExpense() {
        concept = expense.concept
        amountText = expense.amount.formattedAmount()
        currency = expense.currency
        hasDate = expense.hasSpecificDate
        date = expense.date ?? Date()
        note = expense.note ?? ""
        selectedCategory = expense.category
        selectedPerson = expense.paidBy
        isFixedExpense = expense.isFixedExpense
    }

    private func saveChanges() {
        guard let amount = parsedAmount else { return }

        expense.concept = concept.trimmingCharacters(in: .whitespaces)
        expense.amount = amount
        expense.currency = currency
        expense.hasSpecificDate = hasDate
        expense.date = hasDate ? date : nil
        expense.note = note.isEmpty ? nil : note.trimmingCharacters(in: .whitespaces)
        expense.category = selectedCategory
        expense.paidBy = selectedPerson
        expense.isFixedExpense = isFixedExpense
        expense.updatedAt = Date()
    }

    private func deleteExpense() {
        modelContext.delete(expense)
        dismiss()
    }
}

#Preview {
    ExpenseDetailView(
        expense: SampleData.sampleExpense,
        household: SampleData.household
    )
    .modelContainer(SampleData.container)
}
