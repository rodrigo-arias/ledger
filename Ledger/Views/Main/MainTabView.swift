//
//  MainTabView.swift
//  Ledger
//
//  Vista principal con navegación por tabs (iOS) o sidebar (macOS).
//

import SwiftData
import SwiftUI

struct MainTabView: View {
    let household: Household

    @State private var selectedTab = 0
    @State private var selectedYear: Int = Date().year
    @State private var selectedMonth: Int = Date().month

    var body: some View {
        #if os(iOS)
        TabView(selection: $selectedTab) {
            NavigationStack {
                ExpenseListView(
                    household: household,
                    selectedYear: $selectedYear,
                    selectedMonth: $selectedMonth
                )
            }
            .tabItem {
                Label("Gastos", systemImage: "creditcard")
            }
            .tag(0)

            NavigationStack {
                BalanceView(
                    household: household,
                    selectedYear: $selectedYear,
                    selectedMonth: $selectedMonth
                )
            }
            .tabItem {
                Label("Balance", systemImage: "scale.3d")
            }
            .tag(1)

            NavigationStack {
                SettingsPlaceholderView(household: household)
            }
            .tabItem {
                Label("Config", systemImage: "gearshape")
            }
            .tag(2)
        }
        #else
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("Gastos", systemImage: "creditcard")
                    .tag(0)
                Label("Balance", systemImage: "scale.3d")
                    .tag(1)
                Label("Configuración", systemImage: "gearshape")
                    .tag(2)
            }
            .navigationTitle(household.name)
        } detail: {
            switch selectedTab {
            case 0:
                ExpenseListView(
                    household: household,
                    selectedYear: $selectedYear,
                    selectedMonth: $selectedMonth
                )
            case 1:
                BalanceView(
                    household: household,
                    selectedYear: $selectedYear,
                    selectedMonth: $selectedMonth
                )
            case 2:
                SettingsPlaceholderView(household: household)
            default:
                ExpenseListView(
                    household: household,
                    selectedYear: $selectedYear,
                    selectedMonth: $selectedMonth
                )
            }
        }
        #endif
    }
}

// MARK: - Placeholder Views

struct SettingsPlaceholderView: View {
    let household: Household

    @Environment(\.modelContext) private var modelContext

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
        household.categories.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        List {
            Section("Hogar") {
                LabeledContent("Nombre", value: household.name)
            }

            Section("Miembros") {
                ForEach(household.members) { person in
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

            #if DEBUG
            Section("Debug") {
                Picker("Usuario actual", selection: Binding(
                    get: { household.members.first { $0.isCurrentUser }?.id ?? UUID() },
                    set: { newId in
                        for member in household.members {
                            member.isCurrentUser = (member.id == newId)
                        }
                    }
                )) {
                    ForEach(household.members) { person in
                        Text(person.name).tag(person.id)
                    }
                }
            }
            #endif

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
                            if !category.expenses.isEmpty {
                                Text("\(category.expenses.count)")
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
        }
        .navigationTitle("Configuración")
        .alert("Error al eliminar", isPresented: $showingDeleteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage)
        }
        .sheet(isPresented: $showingPersonEditor) {
            NavigationStack {
                Form {
                    Section {
                        TextField("Nombre", text: $personName)
                    }
                }
                .navigationTitle("Editar Miembro")
                .navigationBarTitleDisplayMode(.inline)
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
        .sheet(isPresented: $showingCategoryEditor) {
            NavigationStack {
                Form {
                    Section {
                        TextField("Nombre", text: $categoryName)
                        TextField("Emoji (opcional)", text: $categoryEmoji)
                            .onChange(of: categoryEmoji) { _, newValue in
                                // Limitar a un solo emoji
                                if newValue.count > 1 {
                                    categoryEmoji = String(newValue.prefix(1))
                                }
                            }
                    }

                    if let editing = editingCategory, editing.expenses.isEmpty {
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
                .navigationBarTitleDisplayMode(.inline)
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
        .sheet(isPresented: $showingHistoricalMonthEditor) {
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
                .navigationBarTitleDisplayMode(.inline)
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
    }

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
            let maxSortOrder = household.categories.map(\.sortOrder).max() ?? 0
            let newCategory = Category(
                name: trimmedName,
                emoji: trimmedEmoji.isEmpty ? nil : trimmedEmoji,
                sortOrder: maxSortOrder + 1
            )
            modelContext.insert(newCategory)
            household.categories.append(newCategory)
        }
    }

    private func deleteCategory(at offsets: IndexSet) {
        for index in offsets {
            let category = sortedCategories[index]

            if !category.expenses.isEmpty {
                deleteErrorMessage = "No se puede eliminar '\(category.name)' porque tiene \(category.expenses.count) gasto(s) asociado(s)"
                showingDeleteError = true
                return
            }

            household.categories.removeAll { $0.id == category.id }
            modelContext.delete(category)
        }
    }

    private func deleteCategoryDirectly(_ category: Category) {
        household.categories.removeAll { $0.id == category.id }
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
}

#Preview {
    MainTabView(household: SampleData.household)
        .modelContainer(SampleData.container)
}
