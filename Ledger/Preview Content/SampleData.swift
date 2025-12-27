//
//  SampleData.swift
//  Ledger
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
            MonthlyClose.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])

        SampleDataGeneric.createSampleData(in: container.mainContext)

        return container
    }()

    static var household: Household {
        let context = container.mainContext
        let descriptor = FetchDescriptor<Household>()
        return (try? context.fetch(descriptor).first) ?? Household(name: "Preview")
    }

    static var sampleExpense: Expense {
        (household.expenses ?? []).first ?? Expense(amount: 1_000, concept: "Ejemplo")
    }

    static var samplePerson: Person {
        (household.members ?? []).first ?? Person(name: "Usuario")
    }
}
