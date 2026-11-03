import Foundation
import Observation

@Observable
final class SetFormViewModel {
    enum Mode {
        case create(exerciseID: UUID)
        case edit(WorkoutSet)
    }

    static let defaultReps = 8

    var performedAt: Date
    var weightValue: Double?
    var unit: WeightUnit
    var reps: Int
    /// Sets saved with "Guardar y añadir otra" while the form stayed open.
    private(set) var savedCount = 0
    var errorMessage: String?

    @ObservationIgnored private let mode: Mode
    @ObservationIgnored private let repository: TrainingRepository
    @ObservationIgnored private let now: () -> Date

    init(mode: Mode, repository: TrainingRepository, settings: UserSettings, now: @escaping () -> Date = { .now }) {
        self.mode = mode
        self.repository = repository
        self.now = now

        switch mode {
        case .create(let exerciseID):
            // Prefill with the last set: the next one is usually the same or close.
            let lastSet = (try? repository.sets(forExerciseID: exerciseID))?.first
            performedAt = now()
            weightValue = lastSet?.weight.value
            unit = lastSet?.weight.unit ?? settings.preferredUnit
            reps = lastSet?.reps ?? Self.defaultReps
        case .edit(let set):
            performedAt = set.performedAt
            weightValue = set.weight.value
            unit = set.weight.unit
            reps = set.reps
        }
    }

    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var canSave: Bool {
        guard let weightValue else { return false }
        return weightValue >= 0 && reps >= 1
    }

    /// Returns `true` when the set was saved.
    func save() -> Bool {
        guard canSave, let weightValue else { return false }
        let weight = Weight(value: weightValue, unit: unit)
        let set: WorkoutSet
        switch mode {
        case .create(let exerciseID):
            set = WorkoutSet(exerciseID: exerciseID, performedAt: performedAt, weight: weight, reps: reps)
        case .edit(let original):
            set = WorkoutSet(id: original.id, exerciseID: original.exerciseID, performedAt: performedAt, weight: weight, reps: reps)
        }

        do {
            try repository.saveSet(set)
            return true
        } catch {
            errorMessage = "No se pudo guardar la serie."
            return false
        }
    }

    /// Saves and keeps the values so the next set only needs small tweaks.
    func saveAndAddAnother() {
        guard !isEditing, save() else { return }
        savedCount += 1
        performedAt = now()
    }
}
