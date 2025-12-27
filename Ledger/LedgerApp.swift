//
//  LedgerApp.swift
//  Ledger
//

import SwiftData
import SwiftUI

@main
struct LedgerApp: App {
    // Set to true to use in-memory sample data (no CloudKit)
    private let useSampleData = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Household.self,
            Person.self,
            Category.self,
            MonthlyConfig.self,
            Expense.self,
            Payment.self,
            MonthlyClose.self
        ])

        let containerID = "iCloud.\(Bundle.main.bundleIdentifier!)"
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private(containerID)
        )

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
