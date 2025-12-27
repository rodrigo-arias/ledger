//
//  CurrentUserManager.swift
//  Ledger
//
//  Manages the current user identity per device using UserDefaults.
//  This allows each device to have its own "me" when syncing via CloudKit.
//

import Foundation

final class CurrentUserManager {
    static let shared = CurrentUserManager()

    private let key = "currentPersonId"

    private init() {}

    var currentPersonId: UUID? {
        get {
            guard let string = UserDefaults.standard.string(forKey: key) else { return nil }
            return UUID(uuidString: string)
        }
        set {
            UserDefaults.standard.set(newValue?.uuidString, forKey: key)
        }
    }

    func isCurrentUser(_ person: Person) -> Bool {
        person.id == currentPersonId
    }

    func setCurrentUser(_ person: Person) {
        currentPersonId = person.id
    }

    func clearCurrentUser() {
        currentPersonId = nil
    }
}
