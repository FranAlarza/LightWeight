import Foundation
import Testing
@testable import LightWeight

struct SetFormViewModelTests {
    private let exercise = Exercise(name: "Sentadilla")
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test
    func createPrefillsFromLastSet() {
        // Given
        let last = WorkoutSet(exerciseID: exercise.id, weight: Weight(value: 225, unit: .pounds), reps: 5)
        let repository = InMemoryTrainingRepository(exercises: [exercise], sets: [last])

        // When
        let viewModel = SetFormViewModel(mode: .create(exerciseID: exercise.id), repository: repository, settings: makeSettings())

        // Then
        #expect(viewModel.weightValue == 225)
        #expect(viewModel.unit == .pounds)
        #expect(viewModel.reps == 5)
    }

    @Test
    func createWithoutHistoryUsesDefaults() {
        let repository = InMemoryTrainingRepository(exercises: [exercise])

        let viewModel = SetFormViewModel(mode: .create(exerciseID: exercise.id), repository: repository, settings: makeSettings(unit: .pounds))

        #expect(viewModel.weightValue == nil)
        #expect(viewModel.unit == .pounds)
        #expect(viewModel.reps == SetFormViewModel.defaultReps)
        #expect(!viewModel.canSave)
    }

    @Test(arguments: [(nil, 8, false), (-1, 8, false), (60, 0, false), (0, 10, true), (60, 8, true)] as [(Double?, Int, Bool)])
    func validation(weight: Double?, reps: Int, expected: Bool) {
        let viewModel = SetFormViewModel(mode: .create(exerciseID: exercise.id), repository: InMemoryTrainingRepository(), settings: makeSettings())
        viewModel.weightValue = weight
        viewModel.reps = reps

        #expect(viewModel.canSave == expected)
    }

    @Test
    func editKeepsIdentityAndUpdatesValues() {
        // Given
        let original = WorkoutSet(exerciseID: exercise.id, weight: kg(100), reps: 5)
        let repository = InMemoryTrainingRepository(exercises: [exercise], sets: [original])
        let viewModel = SetFormViewModel(mode: .edit(original), repository: repository, settings: makeSettings())

        // When
        viewModel.weightValue = 102.5
        let saved = viewModel.save()

        // Then
        #expect(saved)
        #expect(repository.storedSets.count == 1)
        #expect(repository.storedSets.first?.id == original.id)
        #expect(repository.storedSets.first?.weight == kg(102.5))
    }

    @Test
    func saveAndAddAnotherKeepsValuesForTheNextSet() {
        // Given
        let repository = InMemoryTrainingRepository(exercises: [exercise])
        let viewModel = SetFormViewModel(mode: .create(exerciseID: exercise.id), repository: repository, settings: makeSettings(), now: { [now] in now })
        viewModel.weightValue = 60
        viewModel.reps = 10

        // When
        viewModel.saveAndAddAnother()
        viewModel.saveAndAddAnother()

        // Then
        #expect(viewModel.savedCount == 2)
        #expect(repository.storedSets.count == 2)
        #expect(Set(repository.storedSets.map(\.id)).count == 2)
        #expect(viewModel.weightValue == 60)
    }

    @Test
    func saveFailureShowsError() {
        let viewModel = SetFormViewModel(mode: .create(exerciseID: exercise.id), repository: FailingTrainingRepository(), settings: makeSettings())
        viewModel.weightValue = 60

        let saved = viewModel.save()

        #expect(!saved)
        #expect(viewModel.errorMessage != nil)
    }
}
