import Foundation

/// Cases are declared in display order.
nonisolated enum MuscleGroup: String, CaseIterable, Codable, Identifiable, Sendable {
    case chest
    case back
    case shoulders
    case arms
    case legs
    case calves
    case abs
    case cardio
    case other

    var id: Self { self }
}

/// Items sharing a muscle group, ready to be shown as a list section.
nonisolated struct MuscleGroupSection<Item: Sendable>: Identifiable, Sendable {
    let group: MuscleGroup
    let items: [Item]

    var id: MuscleGroup { group }

    /// Groups `items` in `MuscleGroup` order, keeping their relative order and skipping empty groups.
    static func sections(of items: [Item], by group: (Item) -> MuscleGroup) -> [MuscleGroupSection] {
        let grouped = Dictionary(grouping: items, by: group)
        return MuscleGroup.allCases.compactMap { muscleGroup in
            grouped[muscleGroup].map { MuscleGroupSection(group: muscleGroup, items: $0) }
        }
    }
}
