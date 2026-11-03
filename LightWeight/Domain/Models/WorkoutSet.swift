import Foundation

nonisolated struct WorkoutSet: Identifiable, Hashable, Sendable {
    let id: UUID
    let exerciseID: UUID
    var performedAt: Date
    var weight: Weight
    var reps: Int

    init(id: UUID = UUID(), exerciseID: UUID, performedAt: Date = .now, weight: Weight, reps: Int) {
        self.id = id
        self.exerciseID = exerciseID
        self.performedAt = performedAt
        self.weight = weight
        self.reps = reps
    }
}

/// All the sets of an exercise performed on the same calendar day.
nonisolated struct DailySets: Identifiable, Hashable, Sendable {
    let day: Date
    let sets: [WorkoutSet]

    var id: Date { day }
}

nonisolated struct ExerciseSummary: Identifiable, Hashable, Sendable {
    let exercise: Exercise
    let lastSet: WorkoutSet?
    let personalRecord: WorkoutSet?

    var id: UUID { exercise.id }
}
