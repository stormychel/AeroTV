//
//  FavoritesManager.swift
//  AeroTV
//

import Foundation

struct Favorite: Codable, Identifiable, Equatable {
    let id: UUID
    let url: String
    let title: String

    init(url: String, title: String) {
        self.id = UUID()
        self.url = url
        self.title = title.isEmpty ? url : title
    }

    init(id: UUID = UUID(), url: String, title: String) {
        self.id = id
        self.url = url
        self.title = title.isEmpty ? url : title
    }
}

final class FavoritesManager {
    static let shared = FavoritesManager()

    private let key = "FAVORITES"
    private let legacyKey = "FAVORITES"

    var favorites: [Favorite] {
        get {
            // Try new Codable format first
            if let data = UserDefaults.standard.data(forKey: "\(key)_v2"),
               let decoded = try? JSONDecoder().decode([Favorite].self, from: data) {
                return decoded
            }
            // Migrate from legacy [[url, title]] format
            return migrateLegacyFavorites()
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: "\(key)_v2")
            }
        }
    }

    func add(url: String, title: String) {
        var current = favorites
        current.append(Favorite(url: url, title: title))
        favorites = current
    }

    func remove(at index: Int) {
        var current = favorites
        guard index >= 0, index < current.count else { return }
        current.remove(at: index)
        favorites = current
    }

    func remove(favorite: Favorite) {
        var current = favorites
        current.removeAll { $0.id == favorite.id }
        favorites = current
    }

    private func migrateLegacyFavorites() -> [Favorite] {
        guard let legacyArray = UserDefaults.standard.array(forKey: legacyKey) as? [[String]] else {
            return []
        }

        let migrated = legacyArray.compactMap { item -> Favorite? in
            guard item.count >= 2 else { return nil }
            let url = item[0]
            let title = item[1]
            guard !url.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
            return Favorite(url: url, title: title)
        }

        // Save in new format
        if !migrated.isEmpty {
            favorites = migrated
        }

        return migrated
    }
}
