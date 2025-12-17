//
//  AddExpenseView.swift
//  Ledger
//
//  Formulario para agregar un nuevo gasto.
//

import SwiftData
import SwiftUI

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let household: Household

    @Query private var allExpenses: [Expense]

    @State private var concept = ""
    @State private var amountText = ""
    @State private var currency: Currency = .ars
    @State private var hasDate = false
    @State private var date = Date()
    @State private var note = ""
    @State private var selectedCategory: Category?
    @State private var selectedPerson: Person?
    @State private var isFixedExpense = false
    @State private var showSuggestions = false
    @FocusState private var isConceptFocused: Bool

    // Sugerencias cacheadas (calculadas una vez al aparecer)
    @State private var cachedConceptsByFrequency: [String] = []

    private var currentUser: Person? {
        household.members.first { $0.isCurrentUser }
    }

    private var categories: [Category] {
        household.categories.sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - Sugerencias de Concepto

    /// Top 5 conceptos más frecuentes para selección rápida
    private var frequentConcepts: [String] {
        Array(cachedConceptsByFrequency.prefix(5))
    }

    /// Sugerencias filtradas según el texto ingresado
    private var filteredSuggestions: [String] {
        guard !concept.isEmpty else { return [] }
        let lowercased = concept.lowercased()
        return cachedConceptsByFrequency.filter {
            $0.lowercased().contains(lowercased) && $0.lowercased() != lowercased
        }.prefix(5).map { $0 }
    }

    /// Calcula frecuencias de conceptos (se ejecuta una vez al aparecer)
    private func loadConceptSuggestions() {
        let householdExpenses = allExpenses.filter { $0.household?.id == household.id }
        let concepts = householdExpenses.map(\.concept)
        let frequency = Dictionary(grouping: concepts, by: { $0 }).mapValues { $0.count }
        cachedConceptsByFrequency = frequency.sorted { $0.value > $1.value }.map(\.key)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Chips de selección rápida para conceptos frecuentes
                if !frequentConcepts.isEmpty, concept.isEmpty {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(frequentConcepts, id: \.self) { suggestion in
                                    Button {
                                        concept = suggestion
                                    } label: {
                                        Text(suggestion)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.accentColor.opacity(0.1))
                                            .foregroundStyle(Color.accentColor)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Frecuentes")
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 0) {
                        TextField("Concepto", text: $concept)
                            .focused($isConceptFocused)
                            .onChange(of: concept) { _, _ in
                                showSuggestions = isConceptFocused && !filteredSuggestions.isEmpty
                            }
                            .onChange(of: isConceptFocused) { _, focused in
                                showSuggestions = focused && !filteredSuggestions.isEmpty
                            }

                        // Sugerencias desplegables
                        if showSuggestions {
                            Divider()
                            ForEach(filteredSuggestions, id: \.self) { suggestion in
                                Button {
                                    concept = suggestion
                                    showSuggestions = false
                                    isConceptFocused = false
                                } label: {
                                    HStack {
                                        Text(suggestion)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                                if suggestion != filteredSuggestions.last {
                                    Divider()
                                }
                            }
                        }
                    }

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
                }

                Section {
                    Picker("Categoría", selection: $selectedCategory) {
                        Text("Sin categoría").tag(nil as Category?)
                        ForEach(categories) { category in
                            Text(category.displayName).tag(category as Category?)
                        }
                    }

                    Picker("Pagó", selection: $selectedPerson) {
                        Text("Seleccionar").tag(nil as Person?)
                        ForEach(household.members) { person in
                            Text(person.name).tag(person as Person?)
                        }
                    }

                    Toggle("Gasto fijo", isOn: $isFixedExpense)

                    Toggle("Agregar fecha", isOn: $hasDate)

                    if hasDate {
                        DatePicker("Fecha", selection: $date, displayedComponents: .date)
                    }
                }

                Section {
                    TextField("Nota (opcional)", text: $note, axis: .vertical)
                        .lineLimit(2 ... 4)
                }
            }
            .navigationTitle("Nuevo Gasto")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Guardar") {
                            saveExpense()
                            dismiss()
                        }
                        .disabled(!isValid)
                    }
                }
                .onAppear {
                    selectedPerson = currentUser
                    selectedCategory = categories.first { $0.name == "Comida" }
                    loadConceptSuggestions()
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

    private func saveExpense() {
        guard let amount = parsedAmount, let paidBy = selectedPerson else { return }

        let expense = Expense(
            amount: amount,
            currency: currency,
            concept: concept.trimmingCharacters(in: .whitespaces),
            note: note.isEmpty ? nil : note.trimmingCharacters(in: .whitespaces),
            date: hasDate ? date : nil,
            hasSpecificDate: hasDate
        )

        expense.category = selectedCategory
        expense.paidBy = paidBy
        expense.household = household
        expense.isFixedExpense = isFixedExpense

        modelContext.insert(expense)
    }
}

#Preview {
    AddExpenseView(household: SampleData.household)
        .modelContainer(SampleData.container)
}
