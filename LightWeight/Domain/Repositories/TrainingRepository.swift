import Foundation

/// Local storage of the user's exercises and sets.
protocol TrainingRepository: AnyObject {
    /// Exercises sorted by name.
    func exercises() throws -> [Exercise]
    func addExercise(_ exercise: Exercise) throws
    func updateExercise(_ exercise: Exercise) throws
    func deleteExercise(id: UUID) throws

    /// Sets of an exercise, newest first.
    func sets(forExerciseID exerciseID: UUID) throws -> [WorkoutSet]
    /// Inserts the set, or updates it when a set with the same id already exists.
    func saveSet(_ set: WorkoutSet) throws
    func deleteSet(id: UUID) throws
}
