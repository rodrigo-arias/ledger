//
//  HouseholdSetupView.swift
//  Ledger
//
//  Vista inicial para configurar el household y las dos personas.
//

import SwiftData
import SwiftUI

struct HouseholdSetupView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var householdName = "Casa"
    @State private var person1Name = ""
    @State private var person2Name = ""
    @State private var currentUserIs1 = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nombre del hogar", text: $householdName)
                } header: {
                    Text("Hogar")
                }

                Section {
                    TextField("Nombre", text: $person1Name)
                    Toggle("Soy yo", isOn: $currentUserIs1)
                } header: {
                    Text("Persona 1")
                }

                Section {
                    TextField("Nombre", text: $person2Name)
                    if currentUserIs1 {
                        Text("Usuario compartido")
                            .foregroundStyle(.secondary)
                    } else {
                        Toggle("Soy yo", isOn: Binding(
                            get: { !currentUserIs1 },
                            set: { currentUserIs1 = !$0 }
                        ))
                    }
                } header: {
                    Text("Persona 2")
                }
            }
            .navigationTitle("Configurar")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Crear") {
                            createHousehold()
                        }
                        .disabled(!isValid)
                    }
                }
        }
    }

    private var isValid: Bool {
        !householdName.trimmingCharacters(in: .whitespaces).isEmpty &&
            !person1Name.trimmingCharacters(in: .whitespaces).isEmpty &&
            !person2Name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func createHousehold() {
        let household = Household(name: householdName.trimmingCharacters(in: .whitespaces))

        let person1 = Person(
            name: person1Name.trimmingCharacters(in: .whitespaces),
            isCurrentUser: currentUserIs1
        )
        let person2 = Person(
            name: person2Name.trimmingCharacters(in: .whitespaces),
            isCurrentUser: !currentUserIs1
        )

        person1.household = household
        person2.household = household
        household.members = [person1, person2]

        // Crear categorías por defecto
        let categories = Category.defaultCategories.enumerated().map { index, cat in
            let category = Category(name: cat.name, emoji: cat.emoji, sortOrder: index)
            category.household = household
            return category
        }
        household.categories = categories

        modelContext.insert(household)
    }
}

#Preview {
    HouseholdSetupView()
        .modelContainer(SampleData.container)
}
