import Foundation
import SwiftData

// Every property has a default value and relationships are optional so the schema
// stays compatible with CloudKit sync when it gets enabled.

@Model
final class ExerciseModel {
    var id: UUID = UUID()
    var name: String = ""
    var catalogSource: String?
    var catalogExternalID: Int?
    var imageURLString: String?
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSetModel.exercise)
    var sets: [WorkoutSetModel]? = []

    init(_ exercise: Exercise) {
        id = exercise.id
        name = exercise.name
        catalogSource = exercise.catalogReference?.source
        catalogExternalID = exercise.catalogReference?.externalID
        imageURLString = exercise.imageURL?.absoluteString
        createdAt = exercise.createdAt
    }

    var domain: Exercise {
        let reference = catalogSource.flatMap { source in
            catalogExternalID.map { CatalogReference(source: source, externalID: $0) }
        }
        return Exercise(
            id: id,
            name: name,
            catalogReference: reference,
            imageURL: imageURLString.flatMap(URL.init(string:)),
            createdAt: createdAt
        )
    }
}

@Model
final class WorkoutSetModel {
    var id: UUID = UUID()
    var performedAt: Date = Date.now
    var weightValue: Double = 0
    var weightUnitRaw: String = WeightUnit.kilograms.rawValue
    var reps: Int = 0
    var exercise: ExerciseModel?

    init(_ set: WorkoutSet, exercise: ExerciseModel) {
        id = set.id
        self.exercise = exercise
        update(from: set)
    }

    func update(from set: WorkoutSet) {
        performedAt = set.performedAt
        weightValue = set.weight.value
        weightUnitRaw = set.weight.unit.rawValue
        reps = set.reps
    }

    /// `nil` when the set lost its exercise, which only happens mid-deletion.
    var domain: WorkoutSet? {
        guard let exerciseID = exercise?.id else { return nil }
        return WorkoutSet(
            id: id,
            exerciseID: exerciseID,
            performedAt: performedAt,
            weight: Weight(value: weightValue, unit: WeightUnit(rawValue: weightUnitRaw) ?? .kilograms),
            reps: reps
        )
    }
}
