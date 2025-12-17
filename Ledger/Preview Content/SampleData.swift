//
//  SampleData.swift
//  Ledger
//
//  Datos de ejemplo para previews de SwiftUI.
//  Usa flag USE_PERSONAL_DATA para cambiar entre datos genéricos y personales.
//
//  Para usar datos personales, agregar en Build Settings:
//  Swift Compiler - Custom Flags > Active Compilation Conditions > Debug:
//  USE_PERSONAL_DATA
//

import Foundation
import SwiftData

@MainActor
enum SampleData {
    static let container: ModelContainer = {
        let schema = Schema([
            Household.self,
            Person.self,
            Category.self,
            MonthlyConfig.self,
            Expense.self,
            Payment.self,
            MonthlyClose.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])

        let context = container.mainContext

        #if USE_PERSONAL_DATA
        SampleDataPersonal.createSampleData(in: context)
        #else
        SampleDataGeneric.createSampleData(in: context)
        #endif

        return container
    }()

    // Accesos rápidos para previews
    static var household: Household {
        let context = container.mainContext
        let descriptor = FetchDescriptor<Household>()
        return (try? context.fetch(descriptor).first) ?? Household(name: "Preview")
    }

    static var sampleExpense: Expense {
        household.expenses.first ?? Expense(amount: 1000, concept: "Ejemplo")
    }

    static var samplePerson: Person {
        household.members.first ?? Person(name: "Usuario")
    }
}
