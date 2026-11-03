import Foundation

/// Read-only source of predefined exercises.
nonisolated protocol ExerciseCatalogService: Sendable {
    /// Exercises whose name contains every word of `query`, ignoring case and diacritics.
    /// An empty query returns everything.
    func search(_ query: String) async throws -> [CatalogExercise]

    /// Warms up the catalog ahead of the first search. Failures are ignored;
    /// the next `search` retries.
    func prefetch() async
}

extension ExerciseCatalogService {
    nonisolated func prefetch() async {
        _ = try? await search("")
    }
}
