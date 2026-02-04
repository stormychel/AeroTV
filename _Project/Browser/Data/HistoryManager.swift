//
//  HistoryManager.swift
//  AeroTV
//

import Foundation

struct HistoryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let url: String
    let title: String
    let timestamp: Date

    init(url: String, title: String) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.timestamp = Date()
    }
}

final class HistoryManager {
    static let shared = HistoryManager()

    private let key = "HISTORY"
    private let maxEntries = 100

    var entries: [HistoryEntry] {
        get {
            // Try new Codable format first
            if let data = UserDefaults.standard.data(forKey: "\(key)_v2"),
               let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
                return decoded
            }
            // Migrate from legacy format
            return migrateLegacyHistory()
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: "\(key)_v2")
            }
        }
    }

    func addEntry(url: String, title: String) {
        var history = entries

        // Don't duplicate consecutive entries
        if history.first?.url == url {
            return
        }

        history.insert(HistoryEntry(url: url, title: title), at: 0)

        // Trim to max
        while history.count > maxEntries {
            history.removeLast()
        }

        entries = history
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: "\(key)_v2")
        UserDefaults.standard.removeObject(forKey: key)
    }

    private func migrateLegacyHistory() -> [HistoryEntry] {
        guard let legacyArray = UserDefaults.standard.array(forKey: key) as? [[String]] else {
            return []
        }

        let migrated = legacyArray.compactMap { item -> HistoryEntry? in
            guard item.count >= 2 else { return nil }
            let url = item[0]
            let title = item[1]
            guard !url.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
            return HistoryEntry(url: url, title: title)
        }

        // Save in new format
        if !migrated.isEmpty {
            entries = migrated
        }

        return migrated
    }
}
