//
//  SyncStatusView.swift
//  Ledger
//
//  Displays CloudKit sync status in the navigation bar.
//

import SwiftUI

struct SyncStatusView: View {
    @ObservedObject var monitor: SyncStatusMonitor = .shared

    var body: some View {
        Group {
            switch monitor.status {
            case .checking:
                ProgressView()
                    .controlSize(.small)
            case .idle:
                Image(systemName: "checkmark.icloud")
                    .foregroundStyle(.green)
            case .syncing:
                ProgressView()
                    .controlSize(.small)
            case .error:
                Image(systemName: "exclamationmark.icloud")
                    .foregroundStyle(.red)
            case .offline:
                Image(systemName: "icloud.slash")
                    .foregroundStyle(.secondary)
            case .noAccount:
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .foregroundStyle(.orange)
            }
        }
        .font(.body)
        .help(statusText)
    }

    private var statusText: String {
        switch monitor.status {
        case .checking:
            return "Checking iCloud..."
        case .idle:
            if let date = monitor.lastSyncDate {
                return "Synced \(date.formatted(.relative(presentation: .named)))"
            }
            return "Synced"
        case .syncing:
            return "Syncing..."
        case let .error(message):
            return "Error: \(message)"
        case .offline:
            return "Offline"
        case .noAccount:
            return "No iCloud account"
        }
    }
}

#Preview {
    SyncStatusView()
}
