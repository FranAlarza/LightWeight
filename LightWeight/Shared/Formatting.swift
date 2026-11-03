import Foundation

extension WeightUnit {
    func formatted(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0...2)))) \(symbol)"
    }

    var title: String {
        switch self {
        case .kilograms: "Kilogramos (kg)"
        case .pounds: "Libras (lb)"
        }
    }
}

extension Weight {
    var formatted: String { unit.formatted(value) }
}

extension WorkoutSet {
    /// "80 kg × 8"
    var summary: String { "\(weight.formatted) × \(reps)" }
}

extension MuscleGroup {
    var title: String {
        switch self {
        case .chest: "Pecho"
        case .back: "Espalda"
        case .shoulders: "Hombros"
        case .arms: "Brazos"
        case .legs: "Piernas"
        case .calves: "Gemelos"
        case .abs: "Abdominales"
        case .cardio: "Cardio"
        case .other: "Otros"
        }
    }
}

extension ProgressMetric {
    var title: String {
        switch self {
        case .maxWeight: "Peso máx."
        case .estimatedOneRepMax: "1RM est."
        case .volume: "Volumen"
        }
    }
}

extension ChartRange {
    var title: String {
        switch self {
        case .oneMonth: "1M"
        case .threeMonths: "3M"
        case .sixMonths: "6M"
        case .oneYear: "1A"
        case .all: "Todo"
        }
    }
}
