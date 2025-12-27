//
//  SettingsView.swift
//  Ledger
//
//  Settings and configuration view.
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    let household: Household

    @Environment(\.modelContext) private var modelContext
    @StateObject private var syncMonitor = SyncStatusMonitor.shared

    @State private var showingHistoricalMonthEditor = false
    @State private var hasHistoricalLimit = false
    @State private var selectedYear = 2_025
    @State private var selectedMonth = 1

    @State private var showingCategoryEditor = false
    @State private var editingCategory: Category?
    @State private var categoryName = ""
    @State private var categoryEmoji = ""

    @State private var showingPersonEditor = false
    @State private var editingPerson: Person?
    @State private var personName = ""

    @State private var showingDeleteError = false
    @State private var deleteErrorMessage = ""

    @State private var showingResetConfirmation = false

    private var historicalMonthText: String {
        if let year = household.historicalDataUntilYear,
           let month = household.historicalDataUntilMonth
        {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "es_AR")
            let monthName = dateFormatter.monthSymbols[month - 1].capitalized
            return "\(monthName) \(year)"
        }
        return "No configurado"
    }

    private var yearRange: [Int] {
        let currentYear = Date().year
        return Array((currentYear - 5) ... currentYear)
    }

    private var monthNames: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_AR")
        return formatter.monthSymbols.map(\.capitalized)
    }

    private var sortedCategories: [Category] {
        (household.categories ?? []).sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        List {
            Section("Hogar") {
                LabeledContent("Nombre", value: household.name)
            }

            Section("Miembros") {
                ForEach(household.members ?? []) { person in
                    Button {
                        editPerson(person)
                    } label: {
                        HStack {
                            Text(person.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if person.isCurrentUser {
                                Text("Yo")
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section("Usuario") {
                Picker("Yo soy", selection: Binding(
                    get: { CurrentUserManager.shared.currentPersonId ?? UUID() },
                    set: { newId in
                        if let person = (household.members ?? []).first(where: { $0.id == newId }) {
                            CurrentUserManager.shared.setCurrentUser(person)
                        }
                    }
                )) {
                    ForEach(household.members ?? []) { person in
                        Text(person.name).tag(person.id)
                    }
                }
            }

            Section("Categorías") {
                ForEach(sortedCategories) { category in
                    Button {
                        editCategory(category)
                    } label: {
                        HStack {
                            if let emoji = category.emoji {
                                Text(emoji)
                            }
                            Text(category.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if !(category.expenses ?? []).isEmpty {
                                Text("\((category.expenses ?? []).count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.tertiary.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .onDelete(perform: deleteCategory)

                Button {
                    addCategory()
                } label: {
                    Label("Agregar categoría", systemImage: "plus.circle.fill")
                }
            }

            Section {
                Button {
                    showingHistoricalMonthEditor = true
                } label: {
                    HStack {
                        Text("Último mes histórico")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(historicalMonthText)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            } footer: {
                Text("Meses anteriores o iguales a esta fecha se consideran históricos y no muestran balance de deuda")
            }

            Section("iCloud") {
                HStack {
                    Text("Estado")
                    Spacer()
                    SyncStatusView(monitor: syncMonitor)
                }
            }

            Section {
                Button(role: .destructive) {
                    showingResetConfirmation = true
                } label: {
                    Label("Borrar todos los datos", systemImage: "trash")
                }
            } header: {
                Text("Datos")
            } footer: {
                Text("Elimina todos los gastos y configuración locales. Útil para reiniciar durante pruebas.")
            }
        }
        .navigationTitle("Configuración")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                SyncStatusView(monitor: syncMonitor)
            }
        }
        .confirmationDialog(
            "¿Borrar todos los datos?",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Borrar todo", role: .destructive) {
                resetAllData()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acción no se puede deshacer. Se eliminarán todos los gastos, pagos y configuración.")
        }
        .alert("Error al eliminar", isPresented: $showingDeleteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage)
        }
        .sheet(isPresented: $showingPersonEditor) {
            personEditorSheet
        }
        .sheet(isPresented: $showingCategoryEditor) {
            categoryEditorSheet
        }
        .sheet(isPresented: $showingHistoricalMonthEditor) {
            historicalMonthEditorSheet
        }
    }

    // MARK: - Sheets

    private var personEditorSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nombre", text: $personName)
                }
            }
            .navigationTitle("Editar Miembro")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        showingPersonEditor = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        savePerson()
                        showingPersonEditor = false
                    }
                    .disabled(personName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var categoryEditorSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nombre", text: $categoryName)
                    TextField("Emoji (opcional)", text: $categoryEmoji)
                        .onChange(of: categoryEmoji) { _, newValue in
                            if newValue.count > 1 {
                                categoryEmoji = String(newValue.prefix(1))
                            }
                        }
                }

                if let editing = editingCategory, (editing.expenses ?? []).isEmpty {
                    Section {
                        Button(role: .destructive) {
                            deleteCategoryDirectly(editing)
                            showingCategoryEditor = false
                        } label: {
                            HStack {
                                Spacer()
                                Text("Eliminar categoría")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(editingCategory == nil ? "Nueva Categoría" : "Editar Categoría")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        showingCategoryEditor = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveCategory()
                        showingCategoryEditor = false
                    }
                    .disabled(categoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var historicalMonthEditorSheet: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Marcar meses como históricos", isOn: $hasHistoricalLimit)
                }

                if hasHistoricalLimit {
                    Section("Seleccionar mes límite") {
                        Picker("Mes", selection: $selectedMonth) {
                            ForEach(1 ... 12, id: \.self) { month in
                                Text(monthNames[month - 1]).tag(month)
                            }
                        }

                        Picker("Año", selection: $selectedYear) {
                            ForEach(yearRange, id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }
                    }
                }
            }
            .onAppear {
                hasHistoricalLimit = household.historicalDataUntilYear != nil
                selectedYear = household.historicalDataUntilYear ?? Date().year
                selectedMonth = household.historicalDataUntilMonth ?? Date().month
            }
            .navigationTitle("Datos Históricos")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        showingHistoricalMonthEditor = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveHistoricalMonth()
                        showingHistoricalMonthEditor = false
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func saveHistoricalMonth() {
        if hasHistoricalLimit {
            household.historicalDataUntilYear = selectedYear
            household.historicalDataUntilMonth = selectedMonth
        } else {
            household.historicalDataUntilYear = nil
            household.historicalDataUntilMonth = nil
        }
    }

    private func addCategory() {
        editingCategory = nil
        categoryName = ""
        categoryEmoji = ""
        showingCategoryEditor = true
    }

    private func editCategory(_ category: Category) {
        editingCategory = category
        categoryName = category.name
        categoryEmoji = category.emoji ?? ""
        showingCategoryEditor = true
    }

    private func saveCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespaces)
        let trimmedEmoji = categoryEmoji.trimmingCharacters(in: .whitespaces)

        if let editing = editingCategory {
            editing.name = trimmedName
            editing.emoji = trimmedEmoji.isEmpty ? nil : trimmedEmoji
        } else {
            let maxSortOrder = (household.categories ?? []).map(\.sortOrder).max() ?? 0
            let newCategory = Category(
                name: trimmedName,
                emoji: trimmedEmoji.isEmpty ? nil : trimmedEmoji,
                sortOrder: maxSortOrder + 1
            )
            newCategory.household = household
            modelContext.insert(newCategory)
        }
    }

    private func deleteCategory(at offsets: IndexSet) {
        for index in offsets {
            let category = sortedCategories[index]
            let expenseCount = (category.expenses ?? []).count

            if expenseCount > 0 {
                deleteErrorMessage = "No se puede eliminar '\(category.name)' porque tiene \(expenseCount) gasto(s) asociado(s)"
                showingDeleteError = true
                return
            }

            modelContext.delete(category)
        }
    }

    private func deleteCategoryDirectly(_ category: Category) {
        modelContext.delete(category)
    }

    private func editPerson(_ person: Person) {
        editingPerson = person
        personName = person.name
        showingPersonEditor = true
    }

    private func savePerson() {
        let trimmedName = personName.trimmingCharacters(in: .whitespaces)
        if let editing = editingPerson {
            editing.name = trimmedName
        }
    }

    private func resetAllData() {
        CurrentUserManager.shared.clearCurrentUser()
        modelContext.delete(household)

        do {
            try modelContext.save()
        } catch {
            deleteErrorMessage = "Error al borrar: \(error.localizedDescription)"
            showingDeleteError = true
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(household: SampleData.household)
    }
    .modelContainer(SampleData.container)
}
