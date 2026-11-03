import Foundation

nonisolated enum ProgressCalculator {
    /// Epley formula. A single rep is already a 1RM.
    static func estimatedOneRepMax(for set: WorkoutSet) -> Double {
        let kilograms = set.weight.kilograms
        guard set.reps > 1 else { return kilograms }
        return kilograms * (1 + Double(set.reps) / 30)
    }

    static func value(of sets: [WorkoutSet], for metric: ProgressMetric) -> Double {
        switch metric {
        case .maxWeight:
            sets.map(\.weight.kilograms).max() ?? 0
        case .estimatedOneRepMax:
            sets.map(estimatedOneRepMax(for:)).max() ?? 0
        case .volume:
            sets.reduce(0) { $0 + $1.weight.kilograms * Double($1.reps) }
        }
    }

    /// Groups sets by day, newest day first and sets in chronological order within each day.
    static func dailyGroups(of sets: [WorkoutSet], calendar: Calendar) -> [DailySets] {
        Dictionary(grouping: sets) { calendar.startOfDay(for: $0.performedAt) }
            .map { DailySets(day: $0.key, sets: $0.value.sorted { $0.performedAt < $1.performedAt }) }
            .sorted { $0.day > $1.day }
    }

    /// Chart points in chronological order, one per training day inside `range`.
    static func progressPoints(
        from sets: [WorkoutSet],
        metric: ProgressMetric,
        range: ChartRange,
        now: Date,
        calendar: Calendar
    ) -> [ProgressPoint] {
        let start = range.startDate(relativeTo: now, calendar: calendar)
        let included = start.map { start in sets.filter { $0.performedAt >= start } } ?? sets
        return dailyGroups(of: included, calendar: calendar)
            .reversed()
            .map { ProgressPoint(date: $0.day, kilograms: value(of: $0.sets, for: metric)) }
    }

    /// Heaviest set ever lifted. On a tie, the first time it was achieved wins.
    static func personalRecord(in sets: [WorkoutSet]) -> WorkoutSet? {
        sets.max { lhs, rhs in
            if lhs.weight.kilograms == rhs.weight.kilograms {
                return lhs.performedAt > rhs.performedAt
            }
            return lhs.weight.kilograms < rhs.weight.kilograms
        }
    }

    static func lastSet(in sets: [WorkoutSet]) -> WorkoutSet? {
        sets.max { $0.performedAt < $1.performedAt }
    }
}
