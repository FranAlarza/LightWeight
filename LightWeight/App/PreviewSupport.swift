#if DEBUG
import Foundation

/// In-memory repository for previews and tests.
final class InMemoryTrainingRepository: TrainingRepository {
    private(set) var storedExercises: [Exercise]
    private(set) var storedSets: [WorkoutSet]

    init(exercises: [Exercise] = [], sets: [WorkoutSet] = []) {
        storedExercises = exercises
        storedSets = sets
    }

    func exercises() throws -> [Exercise] {
        storedExercises.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func addExercise(_ exercise: Exercise) throws {
        storedExercises.append(exercise)
    }

    func deleteExercise(id: UUID) throws {
        storedExercises.removeAll { $0.id == id }
        storedSets.removeAll { $0.exerciseID == id }
    }

    func sets(forExerciseID exerciseID: UUID) throws -> [WorkoutSet] {
        storedSets.filter { $0.exerciseID == exerciseID }.sorted { $0.performedAt > $1.performedAt }
    }

    func saveSet(_ set: WorkoutSet) throws {
        if let index = storedSets.firstIndex(where: { $0.id == set.id }) {
            storedSets[index] = set
        } else {
            storedSets.append(set)
        }
    }

    func deleteSet(id: UUID) throws {
        storedSets.removeAll { $0.id == id }
    }
}

nonisolated struct StaticExerciseCatalog: ExerciseCatalogService {
    var exercises: [CatalogExercise] = [
        "Press de banca", "Sentadilla", "Peso muerto", "Press militar", "Dominadas", "Remo con barra", "Curl de bíceps",
    ].enumerated().map { CatalogExercise(reference: CatalogReference(source: "wger", externalID: $0.offset), name: $0.element) }

    func search(_ query: String) async throws -> [CatalogExercise] {
        query.isEmpty ? exercises : exercises.filter { $0.name.localizedStandardContains(query) }
    }
}

extension AppDependencies {
    static func preview(withSampleData: Bool = true) -> AppDependencies {
        let repository = InMemoryTrainingRepository()
        if withSampleData {
            let bench = Exercise(name: "Press de banca")
            let squat = Exercise(name: "Sentadilla")
            try? repository.addExercise(bench)
            try? repository.addExercise(squat)
            for week in 0..<16 {
                let date = Calendar.current.date(byAdding: .day, value: -week * 5, to: .now) ?? .now
                for (index, reps) in [10, 8, 6].enumerated() {
                    let base = 80 - Double(week) * 1.25 + Double(index) * 2.5
                    try? repository.saveSet(WorkoutSet(exerciseID: bench.id, performedAt: date.addingTimeInterval(Double(index) * 180), weight: Weight(value: base, unit: .kilograms), reps: reps))
                }
            }
        }
        return AppDependencies(repository: repository, catalog: StaticExerciseCatalog(), settings: UserSettings())
    }
}
#endif
