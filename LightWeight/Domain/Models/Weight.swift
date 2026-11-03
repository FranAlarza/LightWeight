import Foundation

nonisolated enum WeightUnit: String, CaseIterable, Codable, Identifiable, Sendable {
    case kilograms = "kg"
    case pounds = "lb"

    var id: Self { self }

    var symbol: String { rawValue }

    var kilogramsPerUnit: Double {
        switch self {
        case .kilograms: 1
        case .pounds: 0.45359237
        }
    }

    func value(fromKilograms kilograms: Double) -> Double {
        kilograms / kilogramsPerUnit
    }
}

/// A weight stored exactly as the user entered it. Use `kilograms` for any calculation.
nonisolated struct Weight: Hashable, Sendable {
    var value: Double
    var unit: WeightUnit

    var kilograms: Double { value * unit.kilogramsPerUnit }

    func converted(to target: WeightUnit) -> Weight {
        guard target != unit else { return self }
        return Weight(value: target.value(fromKilograms: kilograms), unit: target)
    }
}
