import Foundation

nonisolated enum ProgressMetric: String, CaseIterable, Identifiable, Sendable {
    case maxWeight
    case estimatedOneRepMax
    case volume

    var id: Self { self }
}

nonisolated enum ChartRange: String, CaseIterable, Identifiable, Sendable {
    case oneMonth
    case threeMonths
    case sixMonths
    case oneYear
    case all

    var id: Self { self }

    /// First date included in the range, or `nil` when the range is unbounded.
    func startDate(relativeTo now: Date, calendar: Calendar) -> Date? {
        let months: Int
        switch self {
        case .oneMonth: months = 1
        case .threeMonths: months = 3
        case .sixMonths: months = 6
        case .oneYear: months = 12
        case .all: return nil
        }
        return calendar.date(byAdding: .month, value: -months, to: calendar.startOfDay(for: now))
    }
}

/// One value per training day, always expressed in kilograms.
nonisolated struct ProgressPoint: Identifiable, Hashable, Sendable {
    let date: Date
    let kilograms: Double

    var id: Date { date }
}
