import Foundation
import Observation

@Observable
final class ExerciseListViewModel {
    private(set) var summaries: [ExerciseSummary] = []
    private(set) var hasLoaded = false
    var errorMessage: String?

    let settings: UserSettings
    @ObservationIgnored private let repository: TrainingRepository

    init(repository: TrainingRepository, settings: UserSettings) {
        self.repository = repository
        self.settings = settings
    }

    func load() {
        do {
            summaries = try repository.exercises().map { exercise in
                let sets = try repository.sets(forExerciseID: exercise.id)
                return ExerciseSummary(
                    exercise: exercise,
                    lastSet: ProgressCalculator.lastSet(in: sets),
                    personalRecord: ProgressCalculator.personalRecord(in: sets)
                )
            }
        } catch {
            errorMessage = "No se pudieron cargar tus ejercicios."
        }
        hasLoaded = true
    }

    func delete(_ summary: ExerciseSummary) {
        do {
            try repository.deleteExercise(id: summary.exercise.id)
            summaries.removeAll { $0.id == summary.id }
        } catch {
            errorMessage = "No se pudo borrar «\(summary.exercise.name)»."
        }
    }
}
