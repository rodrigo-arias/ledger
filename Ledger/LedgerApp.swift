//
//  LedgerApp.swift
//  Ledger
//

import SwiftUI
import SwiftData

@main
struct LedgerApp: App {
    #if DEBUG
    // Usar datos de ejemplo para testing
    private let useSampleData = true
    #else
    private let useSampleData = false
    #endif

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Household.self,
            Person.self,
            Category.self,
            MonthlyConfig.self,
            Expense.self,
            Payment.self,
            MonthlyClose.self,
        ])

        #if DEBUG
        // En desarrollo, usar almacenamiento en memoria para evitar problemas de migración
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        #else
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        #endif

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(useSampleData ? SampleData.container : sharedModelContainer)
    }
}
