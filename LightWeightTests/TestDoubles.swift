import Foundation
@testable import LightWeight

nonisolated struct TestError: Error {}

/// Repository whose every operation fails.
final class FailingTrainingRepository: TrainingRepository {
    func exercises() throws -> [Exercise] { throw TestError() }
    func addExercise(_ exercise: Exercise) throws { throw TestError() }
    func updateExercise(_ exercise: Exercise) throws { throw TestError() }
    func deleteExercise(id: UUID) throws { throw TestError() }
    func sets(forExerciseID exerciseID: UUID) throws -> [WorkoutSet] { throw TestError() }
    func saveSet(_ set: WorkoutSet) throws { throw TestError() }
    func deleteSet(id: UUID) throws { throw TestError() }
}

nonisolated struct FailingCatalog: ExerciseCatalogService {
    func search(_ query: String) async throws -> [CatalogExercise] { throw TestError() }
}

func makeSettings(unit: WeightUnit = .kilograms) -> UserSettings {
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    let settings = UserSettings(defaults: defaults)
    settings.preferredUnit = unit
    return settings
}

func kg(_ value: Double) -> Weight { Weight(value: value, unit: .kilograms) }
