//
//  SyncStatusMonitor.swift
//  Ledger
//
//  Monitors CloudKit sync status and account availability.
//

import CloudKit
import Combine
import Foundation

@MainActor
final class SyncStatusMonitor: ObservableObject {
    static let shared = SyncStatusMonitor()

    @Published var status: SyncStatus = .checking
    @Published var lastSyncDate: Date?
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine

    enum SyncStatus {
        case checking
        case idle
        case syncing
        case error(String)
        case offline
        case noAccount
    }

    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupAccountMonitoring()
        Task {
            await checkAccountStatus()
        }
    }

    private func setupAccountMonitoring() {
        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.checkAccountStatus()
                }
            }
            .store(in: &cancellables)
    }

    func checkAccountStatus() async {
        do {
            let status = try await CKContainer.default().accountStatus()
            accountStatus = status

            switch status {
            case .available:
                self.status = .idle
            case .noAccount:
                self.status = .noAccount
            case .restricted, .couldNotDetermine:
                self.status = .error("iCloud unavailable")
            case .temporarilyUnavailable:
                self.status = .offline
            @unknown default:
                self.status = .error("Unknown status")
            }
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    func markSyncing() {
        status = .syncing
    }

    func markSynced() {
        status = .idle
        lastSyncDate = Date()
    }

    func markError(_ message: String) {
        status = .error(message)
    }
}
