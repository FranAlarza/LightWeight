import Foundation
import Observation

@Observable
final class ExerciseListViewModel {
    private(set) var summaries: [ExerciseSummary] = [] {
        didSet { sections = MuscleGroupSection.sections(of: summaries, by: \.exercise.muscleGroup) }
    }
    private(set) var sections: [MuscleGroupSection<ExerciseSummary>] = []
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

    func move(_ summary: ExerciseSummary, to muscleGroup: MuscleGroup) {
        var exercise = summary.exercise
        exercise.muscleGroup = muscleGroup
        do {
            try repository.updateExercise(exercise)
            load()
        } catch {
            errorMessage = "No se pudo cambiar el grupo de «\(exercise.name)»."
        }
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
