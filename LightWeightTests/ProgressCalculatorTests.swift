import Foundation
import Testing
@testable import LightWeight

struct ProgressCalculatorTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
    private let exerciseID = UUID()

    private func date(_ day: Int, month: Int = 10, hour: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    private func set(_ kilograms: Double, reps: Int, at date: Date) -> WorkoutSet {
        WorkoutSet(exerciseID: exerciseID, performedAt: date, weight: Weight(value: kilograms, unit: .kilograms), reps: reps)
    }

    @Test
    func oneRepMaxUsesEpleyFormula() {
        // Given
        let workoutSet = set(100, reps: 10, at: date(1))

        // When
        let oneRepMax = ProgressCalculator.estimatedOneRepMax(for: workoutSet)

        // Then
        #expect(abs(oneRepMax - 133.333_333) < 0.001)
    }

    @Test
    func oneRepMaxOfSingleRepIsTheLiftedWeight() {
        let workoutSet = set(140, reps: 1, at: date(1))

        #expect(ProgressCalculator.estimatedOneRepMax(for: workoutSet) == 140)
    }

    @Test(arguments: [
        (ProgressMetric.maxWeight, 100.0),
        (ProgressMetric.estimatedOneRepMax, 120.0),
        (ProgressMetric.volume, 1_300.0),
    ])
    func metricValueForADay(metric: ProgressMetric, expected: Double) {
        // Given
        let sets = [set(90, reps: 10, at: date(1)), set(100, reps: 4, at: date(1))]

        // When
        let value = ProgressCalculator.value(of: sets, for: metric)

        // Then
        #expect(abs(value - expected) < 0.001)
    }

    @Test
    func valuesAreNormalizedToKilograms() {
        // Given
        let sets = [WorkoutSet(exerciseID: exerciseID, weight: Weight(value: 220.462_262, unit: .pounds), reps: 1)]

        // When
        let value = ProgressCalculator.value(of: sets, for: .maxWeight)

        // Then
        #expect(abs(value - 100) < 0.001)
    }

    @Test
    func dailyGroupsAreNewestFirstWithChronologicalSets() {
        // Given
        let early = set(80, reps: 8, at: date(2, hour: 9))
        let late = set(85, reps: 8, at: date(2, hour: 11))
        let older = set(75, reps: 8, at: date(1))

        // When
        let groups = ProgressCalculator.dailyGroups(of: [late, older, early], calendar: calendar)

        // Then
        #expect(groups.map(\.day) == [calendar.startOfDay(for: date(2)), calendar.startOfDay(for: date(1))])
        #expect(groups.first?.sets == [early, late])
    }

    @Test
    func progressPointsAreChronologicalAndFilteredByRange() {
        // Given
        let now = date(30)
        let sets = [
            set(60, reps: 5, at: date(1, month: 6)),
            set(70, reps: 5, at: date(10)),
            set(80, reps: 5, at: date(20)),
        ]

        // When
        let points = ProgressCalculator.progressPoints(
            from: sets, metric: .maxWeight, range: .oneMonth, now: now, calendar: calendar
        )

        // Then
        #expect(points.map(\.kilograms) == [70, 80])
    }

    @Test
    func allRangeKeepsEverySet() {
        let sets = [set(60, reps: 5, at: date(1, month: 1)), set(80, reps: 5, at: date(20))]

        let points = ProgressCalculator.progressPoints(
            from: sets, metric: .maxWeight, range: .all, now: date(30), calendar: calendar
        )

        #expect(points.count == 2)
    }

    @Test
    func personalRecordPrefersFirstTimeOnTie() {
        // Given
        let first = set(100, reps: 3, at: date(1))
        let repeated = set(100, reps: 5, at: date(5))
        let lighter = set(90, reps: 10, at: date(8))

        // When
        let record = ProgressCalculator.personalRecord(in: [repeated, lighter, first])

        // Then
        #expect(record == first)
    }

    @Test
    func emptySetsHaveNoRecordOrLastSet() {
        #expect(ProgressCalculator.personalRecord(in: []) == nil)
        #expect(ProgressCalculator.lastSet(in: []) == nil)
    }
}
