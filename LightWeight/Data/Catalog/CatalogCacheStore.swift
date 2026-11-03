import Foundation

/// A downloaded catalog together with when and in which language it was fetched.
nonisolated struct CatalogSnapshot: Codable, Equatable, Sendable {
    let fetchedAt: Date
    let languageID: Int
    let exercises: [CatalogExercise]
}

nonisolated protocol CatalogCacheStore: Sendable {
    func load() async -> CatalogSnapshot?
    func save(_ snapshot: CatalogSnapshot) async
}

/// Keeps the last downloaded catalog as JSON in the Caches directory.
/// Failures are ignored: a missing or unreadable cache only means downloading again.
nonisolated struct FileCatalogCacheStore: CatalogCacheStore {
    let fileURL: URL

    init(fileURL: URL = URL.cachesDirectory.appending(path: "wger-catalog.json")) {
        self.fileURL = fileURL
    }

    func load() async -> CatalogSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(CatalogSnapshot.self, from: data)
    }

    func save(_ snapshot: CatalogSnapshot) async {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
