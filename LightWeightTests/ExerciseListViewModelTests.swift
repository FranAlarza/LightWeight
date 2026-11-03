import Foundation
import Testing
@testable import LightWeight

struct ExerciseListViewModelTests {
    @Test
    func loadBuildsSummariesWithLastSetAndRecord() {
        // Given
        let bench = Exercise(name: "Press banca")
        let heavy = WorkoutSet(exerciseID: bench.id, performedAt: .now.addingTimeInterval(-86_400), weight: kg(100), reps: 3)
        let latest = WorkoutSet(exerciseID: bench.id, performedAt: .now, weight: kg(80), reps: 8)
        let repository = InMemoryTrainingRepository(exercises: [bench], sets: [heavy, latest])
        let viewModel = ExerciseListViewModel(repository: repository, settings: makeSettings())

        // When
        viewModel.load()

        // Then
        #expect(viewModel.hasLoaded)
        #expect(viewModel.summaries == [ExerciseSummary(exercise: bench, lastSet: latest, personalRecord: heavy)])
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func loadWithNoExercisesIsLoadedAndEmpty() {
        let viewModel = ExerciseListViewModel(repository: InMemoryTrainingRepository(), settings: makeSettings())

        viewModel.load()

        #expect(viewModel.hasLoaded)
        #expect(viewModel.summaries.isEmpty)
    }

    @Test
    func loadFailureShowsError() {
        let viewModel = ExerciseListViewModel(repository: FailingTrainingRepository(), settings: makeSettings())

        viewModel.load()

        #expect(viewModel.errorMessage != nil)
    }

    @Test
    func deleteRemovesTheExercise() {
        // Given
        let exercise = Exercise(name: "Remo")
        let repository = InMemoryTrainingRepository(exercises: [exercise])
        let viewModel = ExerciseListViewModel(repository: repository, settings: makeSettings())
        viewModel.load()

        // When
        viewModel.delete(viewModel.summaries[0])

        // Then
        #expect(viewModel.summaries.isEmpty)
        #expect(repository.storedExercises.isEmpty)
    }

    @Test
    func summariesAreGroupedByMuscleGroup() {
        // Given
        let squat = Exercise(name: "Sentadilla", muscleGroup: .legs)
        let bench = Exercise(name: "Press banca", muscleGroup: .chest)
        let custom = Exercise(name: "Mi ejercicio")
        let viewModel = ExerciseListViewModel(
            repository: InMemoryTrainingRepository(exercises: [squat, bench, custom]),
            settings: makeSettings()
        )

        // When
        viewModel.load()

        // Then
        #expect(viewModel.sections.map(\.group) == [.chest, .legs, .other])
    }

    @Test
    func movingAnExerciseChangesItsSection() {
        // Given
        let exercise = Exercise(name: "Bench Press")
        let repository = InMemoryTrainingRepository(exercises: [exercise])
        let viewModel = ExerciseListViewModel(repository: repository, settings: makeSettings())
        viewModel.load()

        // When
        viewModel.move(viewModel.summaries[0], to: .chest)

        // Then
        #expect(viewModel.sections.map(\.group) == [.chest])
        #expect(repository.storedExercises.first?.muscleGroup == .chest)
    }

    @Test
    func moveFailureShowsError() {
        let viewModel = ExerciseListViewModel(repository: FailingTrainingRepository(), settings: makeSettings())
        let summary = ExerciseSummary(exercise: Exercise(name: "Remo"), lastSet: nil, personalRecord: nil)

        viewModel.move(summary, to: .back)

        #expect(viewModel.errorMessage != nil)
    }
}
