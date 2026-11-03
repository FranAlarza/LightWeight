import Foundation
import Observation

@Observable
final class UserSettings {
    private enum Keys {
        static let preferredUnit = "preferredWeightUnit"
    }

    @ObservationIgnored private let defaults: UserDefaults

    /// Unit used for charts and metrics. Sets keep the unit they were entered in.
    var preferredUnit: WeightUnit {
        didSet { defaults.set(preferredUnit.rawValue, forKey: Keys.preferredUnit) }
    }

    init(defaults: UserDefaults = .standard, locale: Locale = .current) {
        self.defaults = defaults
        let stored = defaults.string(forKey: Keys.preferredUnit).flatMap(WeightUnit.init(rawValue:))
        preferredUnit = stored ?? (locale.measurementSystem == .us ? .pounds : .kilograms)
    }
}
