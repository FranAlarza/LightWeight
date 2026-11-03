import Foundation
import Testing
@testable import LightWeight

struct ExerciseDetailViewModelTests {
    private let exercise = Exercise(name: "Press banca")
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeViewModel(sets: [WorkoutSet], unit: WeightUnit = .kilograms) -> (ExerciseDetailViewModel, InMemoryTrainingRepository) {
        let repository = InMemoryTrainingRepository(exercises: [exercise], sets: sets)
        let viewModel = ExerciseDetailViewModel(
            exercise: exercise, repository: repository, settings: makeSettings(unit: unit), now: { [now] in now }
        )
        return (viewModel, repository)
    }

    private func set(_ kilograms: Double, reps: Int, daysAgo: Double) -> WorkoutSet {
        WorkoutSet(exerciseID: exercise.id, performedAt: now.addingTimeInterval(-daysAgo * 86_400), weight: kg(kilograms), reps: reps)
    }

    @Test
    func loadBuildsHistoryRecordAndPoints() {
        // Given
        let (viewModel, _) = makeViewModel(sets: [set(80, reps: 8, daysAgo: 7), set(85, reps: 5, daysAgo: 1)])

        // When
        viewModel.load()

        // Then
        #expect(viewModel.hasSets)
        #expect(viewModel.history.count == 2)
        #expect(viewModel.personalRecord?.weight == kg(85))
        #expect(viewModel.chartPoints.map(\.value) == [80, 85])
    }

    @Test
    func changingMetricRecomputesPoints() {
        // Given
        let (viewModel, _) = makeViewModel(sets: [set(100, reps: 10, daysAgo: 1)])
        viewModel.load()

        // When
        viewModel.metric = .volume

        // Then
        #expect(viewModel.chartPoints.map(\.value) == [1_000])
    }

    @Test
    func changingRangeFiltersOldSets() {
        // Given
        let (viewModel, _) = makeViewModel(sets: [set(60, reps: 5, daysAgo: 200), set(80, reps: 5, daysAgo: 10)])
        viewModel.load()

        // When
        viewModel.range = .oneMonth

        // Then
        #expect(viewModel.chartPoints.map(\.value) == [80])
    }

    @Test
    func chartUsesThePreferredUnit() {
        let (viewModel, _) = makeViewModel(sets: [set(100, reps: 1, daysAgo: 1)], unit: .pounds)

        viewModel.load()

        let value = viewModel.chartPoints.first?.value ?? 0
        #expect(abs(value - 220.462) < 0.001)
    }

    @Test
    func deleteRemovesSetAndReloads() {
        // Given
        let doomed = set(80, reps: 8, daysAgo: 1)
        let (viewModel, repository) = makeViewModel(sets: [doomed])
        viewModel.load()

        // When
        viewModel.delete(doomed)

        // Then
        #expect(repository.storedSets.isEmpty)
        #expect(!viewModel.hasSets)
        #expect(viewModel.history.isEmpty)
    }

    @Test
    func singleValueGetsAPaddedValueDomain() {
        // Given
        let (viewModel, _) = makeViewModel(sets: [set(60, reps: 8, daysAgo: 0)])

        // When
        viewModel.load()

        // Then
        let domain = viewModel.chartValueDomain
        #expect(domain.lowerBound < 60 && domain.upperBound > 60)
    }

    @Test
    func dateDomainCoversTheRangeAndAtLeastAWeek() {
        // Given
        let (viewModel, _) = makeViewModel(sets: [set(60, reps: 8, daysAgo: 0)])
        viewModel.load()

        // When
        viewModel.range = .oneMonth
        let monthSpan = viewModel.chartDateDomain.upperBound.timeIntervalSince(viewModel.chartDateDomain.lowerBound)
        viewModel.range = .all
        let allSpan = viewModel.chartDateDomain.upperBound.timeIntervalSince(viewModel.chartDateDomain.lowerBound)

        // Then
        #expect(monthSpan >= 28 * 86_400)
        #expect(allSpan >= 7 * 86_400)
    }

    @Test
    func loadFailureShowsError() {
        let viewModel = ExerciseDetailViewModel(exercise: exercise, repository: FailingTrainingRepository(), settings: makeSettings())

        viewModel.load()

        #expect(viewModel.errorMessage != nil)
    }
}
