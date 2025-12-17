//
//  ContentView.swift
//  Ledger
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var households: [Household]

    var body: some View {
        if let household = households.first {
            MainTabView(household: household)
        } else {
            HouseholdSetupView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(SampleData.container)
}
