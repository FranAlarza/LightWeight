import Foundation
import SwiftData
import Testing
@testable import LightWeight

struct SwiftDataTrainingRepositoryTests {
    private let container: ModelContainer
    private let repository: SwiftDataTrainingRepository

    init() throws {
        container = try SwiftDataTrainingRepository.makeContainer(inMemory: true)
        repository = SwiftDataTrainingRepository(context: container.mainContext)
    }

    @Test
    func exercisesAreSortedByName() throws {
        // Given
        try repository.addExercise(Exercise(name: "Sentadilla"))
        try repository.addExercise(Exercise(name: "Press banca"))

        // When
        let names = try repository.exercises().map(\.name)

        // Then
        #expect(names == ["Press banca", "Sentadilla"])
    }

    @Test
    func catalogReferenceAndImageRoundTrip() throws {
        // Given
        let reference = CatalogReference(source: "wger", externalID: 73)
        let imageURL = URL(string: "https://wger.de/media/exercise-images/73/bench.png")
        try repository.addExercise(Exercise(name: "Press banca", catalogReference: reference, imageURL: imageURL))

        // When
        let stored = try repository.exercises().first

        // Then
        #expect(stored?.catalogReference == reference)
        #expect(stored?.imageURL == imageURL)
    }

    @Test
    func updatingAnExerciseChangesItsMuscleGroup() throws {
        // Given
        var exercise = Exercise(name: "Bench Press")
        try repository.addExercise(exercise)

        // When
        exercise.muscleGroup = .chest
        try repository.updateExercise(exercise)

        // Then
        #expect(try repository.exercises() == [exercise])
    }

    @Test
    func updatingAMissingExerciseFails() {
        #expect(throws: TrainingRepositoryError.exerciseNotFound) {
            try repository.updateExercise(Exercise(name: "Fantasma"))
        }
    }

    @Test
    func savingAnExistingSetUpdatesIt() throws {
        // Given
        let exercise = Exercise(name: "Peso muerto")
        try repository.addExercise(exercise)
        var workoutSet = WorkoutSet(exerciseID: exercise.id, weight: Weight(value: 100, unit: .kilograms), reps: 5)
        try repository.saveSet(workoutSet)

        // When
        workoutSet.weight = Weight(value: 225, unit: .pounds)
        workoutSet.reps = 3
        try repository.saveSet(workoutSet)

        // Then
        let sets = try repository.sets(forExerciseID: exercise.id)
        #expect(sets == [workoutSet])
    }

    @Test
    func setsAreNewestFirstAndScopedToTheirExercise() throws {
        // Given
        let bench = Exercise(name: "Press banca")
        let squat = Exercise(name: "Sentadilla")
        try repository.addExercise(bench)
        try repository.addExercise(squat)
        let older = WorkoutSet(exerciseID: bench.id, performedAt: .now.addingTimeInterval(-3_600), weight: Weight(value: 60, unit: .kilograms), reps: 8)
        let newer = WorkoutSet(exerciseID: bench.id, weight: Weight(value: 65, unit: .kilograms), reps: 8)
        try repository.saveSet(older)
        try repository.saveSet(newer)
        try repository.saveSet(WorkoutSet(exerciseID: squat.id, weight: Weight(value: 100, unit: .kilograms), reps: 5))

        // When
        let sets = try repository.sets(forExerciseID: bench.id)

        // Then
        #expect(sets == [newer, older])
    }

    @Test
    func savingASetForAMissingExerciseFails() {
        let orphan = WorkoutSet(exerciseID: UUID(), weight: Weight(value: 20, unit: .kilograms), reps: 10)

        #expect(throws: TrainingRepositoryError.exerciseNotFound) {
            try repository.saveSet(orphan)
        }
    }

    @Test
    func deletingAnExerciseDeletesItsSets() throws {
        // Given
        let exercise = Exercise(name: "Remo")
        try repository.addExercise(exercise)
        try repository.saveSet(WorkoutSet(exerciseID: exercise.id, weight: Weight(value: 50, unit: .kilograms), reps: 10))

        // When
        try repository.deleteExercise(id: exercise.id)

        // Then
        #expect(try repository.exercises().isEmpty)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<WorkoutSetModel>()) == 0)
    }

    @Test
    func deletingASetRemovesOnlyThatSet() throws {
        // Given
        let exercise = Exercise(name: "Curl")
        try repository.addExercise(exercise)
        let kept = WorkoutSet(exerciseID: exercise.id, weight: Weight(value: 12, unit: .kilograms), reps: 12)
        let removed = WorkoutSet(exerciseID: exercise.id, weight: Weight(value: 14, unit: .kilograms), reps: 10)
        try repository.saveSet(kept)
        try repository.saveSet(removed)

        // When
        try repository.deleteSet(id: removed.id)

        // Then
        #expect(try repository.sets(forExerciseID: exercise.id) == [kept])
    }
}
