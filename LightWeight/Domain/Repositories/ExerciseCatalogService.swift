import Foundation

/// Read-only source of predefined exercises.
nonisolated protocol ExerciseCatalogService: Sendable {
    /// Exercises whose name contains `query`, ignoring case and diacritics. An empty query returns everything.
    func search(_ query: String) async throws -> [CatalogExercise]
}
