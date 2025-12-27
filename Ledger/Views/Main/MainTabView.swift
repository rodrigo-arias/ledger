//
//  MainTabView.swift
//  Ledger
//
//  Main navigation with tabs (iOS) or sidebar (macOS).
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
                SettingsView(household: household)
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
                SettingsView(household: household)
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

#Preview {
    MainTabView(household: SampleData.household)
        .modelContainer(SampleData.container)
}
