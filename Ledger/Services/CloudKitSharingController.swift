//
//  CloudKitSharingController.swift
//  Ledger
//
//  Manages CloudKit sharing for Household data between two users.
//

import CloudKit
import Combine
import SwiftUI

@MainActor
final class CloudKitSharingController: ObservableObject {
    static let shared = CloudKitSharingController()

    @Published var shareStatus: ShareStatus = .unknown
    @Published var isLoading = false
    @Published var error: Error?

    enum ShareStatus {
        case unknown
        case notShared
        case owner
        case participant
    }

    private let container = CKContainer.default()

    private init() {}

    func checkShareStatus() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let status = try await container.accountStatus()
            guard status == .available else {
                shareStatus = .unknown
                return
            }

            // Try to fetch zones from shared database
            let sharedZones = try await container.sharedCloudDatabase.allRecordZones()

            if !sharedZones.isEmpty {
                shareStatus = .participant
                return
            }

            // Check if we have shares in private database
            // This is a simplified check - in production you'd query for CKShare records
            shareStatus = .notShared

        } catch {
            self.error = error
            shareStatus = .unknown
        }
    }

    func acceptShare(from metadata: CKShare.Metadata) async throws {
        isLoading = true
        defer { isLoading = false }

        try await container.accept(metadata)
        shareStatus = .participant
    }

    func acceptShare(from url: URL) async throws {
        isLoading = true
        defer { isLoading = false }

        let metadata = try await container.shareMetadata(for: url)
        try await container.accept(metadata)
        shareStatus = .participant
    }
}
