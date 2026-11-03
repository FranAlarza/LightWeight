import Foundation
import Observation

/// A chart point converted to the unit currently shown.
struct ChartPoint: Identifiable, Hashable {
    let date: Date
    let value: Double

    var id: Date { date }
}

@Observable
final class ExerciseDetailViewModel {
    let exercise: Exercise
    let settings: UserSettings

    var metric: ProgressMetric = .maxWeight {
        didSet { recomputePoints() }
    }
    var range: ChartRange = .threeMonths {
        didSet { recomputePoints() }
    }
    private(set) var history: [DailySets] = []
    private(set) var personalRecord: WorkoutSet?
    private(set) var hasLoaded = false
    var errorMessage: String?

    private var sets: [WorkoutSet] = []
    private var points: [ProgressPoint] = []

    @ObservationIgnored private let repository: TrainingRepository
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored private let now: () -> Date

    init(
        exercise: Exercise,
        repository: TrainingRepository,
        settings: UserSettings,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { .now }
    ) {
        self.exercise = exercise
        self.repository = repository
        self.settings = settings
        self.calendar = calendar
        self.now = now
    }

    var unit: WeightUnit { settings.preferredUnit }

    var hasSets: Bool { !sets.isEmpty }

    /// Chart values in the preferred unit. Volume is shown as weight × reps in that unit.
    var chartPoints: [ChartPoint] {
        points.map { ChartPoint(date: $0.date, value: unit.value(fromKilograms: $0.kilograms)) }
    }

    /// X axis from the start of the range to the end of today, never shorter than a week
    /// so a single training day is not stretched over hours.
    var chartDateDomain: ClosedRange<Date> {
        let today = calendar.startOfDay(for: now())
        let end = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let minimumStart = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let rangeStart = range.startDate(relativeTo: now(), calendar: calendar) ?? points.first?.date ?? minimumStart
        return min(rangeStart, minimumStart)...end
    }

    /// Y axis with some padding so flat or single-value series still get a readable scale.
    var chartValueDomain: ClosedRange<Double> {
        let values = chartPoints.map(\.value)
        guard let low = values.min(), let high = values.max() else { return 0...1 }
        let padding = max((high - low) * 0.1, high * 0.05, 1)
        return max(0, low - padding)...(high + padding)
    }

    func load() {
        do {
            sets = try repository.sets(forExerciseID: exercise.id)
            history = ProgressCalculator.dailyGroups(of: sets, calendar: calendar)
            personalRecord = ProgressCalculator.personalRecord(in: sets)
            recomputePoints()
        } catch {
            errorMessage = "No se pudo cargar el histórico."
        }
        hasLoaded = true
    }

    func delete(_ set: WorkoutSet) {
        do {
            try repository.deleteSet(id: set.id)
            load()
        } catch {
            errorMessage = "No se pudo borrar la serie."
        }
    }

    private func recomputePoints() {
        points = ProgressCalculator.progressPoints(
            from: sets, metric: metric, range: range, now: now(), calendar: calendar
        )
    }
}
