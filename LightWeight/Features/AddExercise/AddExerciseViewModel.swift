import Foundation
import Observation

@Observable
final class AddExerciseViewModel {
    enum CatalogState: Equatable {
        case idle
        case loading
        case loaded
        case failed
    }

    var query = ""
    private(set) var results: [CatalogExercise] = [] {
        didSet { sections = MuscleGroupSection.sections(of: results, by: \.muscleGroup) }
    }
    private(set) var sections: [MuscleGroupSection<CatalogExercise>] = []
    private(set) var catalogState: CatalogState = .idle
    var errorMessage: String?

    @ObservationIgnored private let catalog: ExerciseCatalogService
    @ObservationIgnored private let repository: TrainingRepository

    init(catalog: ExerciseCatalogService, repository: TrainingRepository) {
        self.catalog = catalog
        self.repository = repository
    }

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Offer a custom exercise unless the catalog already has that exact name.
    var canCreateCustom: Bool {
        !trimmedQuery.isEmpty
            && !results.contains { $0.name.compare(trimmedQuery, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }
    }

    func search() async {
        if results.isEmpty { catalogState = .loading }
        do {
            let found = try await catalog.search(query)
            try Task.checkCancellation()
            results = found
            catalogState = .loaded
        } catch is CancellationError {
            // A newer query replaced this one.
        } catch {
            results = []
            catalogState = .failed
        }
    }

    /// Returns `true` when the exercise was saved and the screen can close.
    func add(_ item: CatalogExercise) -> Bool {
        save(Exercise(
            name: item.name,
            muscleGroup: item.muscleGroup,
            catalogReference: item.reference,
            imageURL: item.imageURL
        ))
    }

    func addCustom(muscleGroup: MuscleGroup) -> Bool {
        guard !trimmedQuery.isEmpty else { return false }
        return save(Exercise(name: trimmedQuery, muscleGroup: muscleGroup))
    }

    private func save(_ exercise: Exercise) -> Bool {
        do {
            try repository.addExercise(exercise)
            return true
        } catch {
            errorMessage = "No se pudo guardar «\(exercise.name)»."
            return false
        }
    }
}
