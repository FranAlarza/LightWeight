import Foundation
import SwiftData

enum TrainingRepositoryError: Error, Equatable {
    case exerciseNotFound
}

final class SwiftDataTrainingRepository: TrainingRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([ExerciseModel.self, WorkoutSetModel.self])
        // CloudKit stays off explicitly until sync becomes a feature.
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: configuration)
    }

    func exercises() throws -> [Exercise] {
        try context.fetch(FetchDescriptor<ExerciseModel>())
            .map(\.domain)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func addExercise(_ exercise: Exercise) throws {
        context.insert(ExerciseModel(exercise))
        try context.save()
    }

    func updateExercise(_ exercise: Exercise) throws {
        guard let model = try exerciseModel(id: exercise.id) else {
            throw TrainingRepositoryError.exerciseNotFound
        }
        model.update(from: exercise)
        try context.save()
    }

    func deleteExercise(id: UUID) throws {
        guard let model = try exerciseModel(id: id) else { return }
        context.delete(model)
        try context.save()
    }

    func sets(forExerciseID exerciseID: UUID) throws -> [WorkoutSet] {
        let descriptor = FetchDescriptor<WorkoutSetModel>(
            predicate: #Predicate { $0.exercise?.id == exerciseID },
            sortBy: [SortDescriptor(\.performedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).compactMap(\.domain)
    }

    func saveSet(_ set: WorkoutSet) throws {
        if let existing = try setModel(id: set.id) {
            existing.update(from: set)
        } else {
            guard let exercise = try exerciseModel(id: set.exerciseID) else {
                throw TrainingRepositoryError.exerciseNotFound
            }
            context.insert(WorkoutSetModel(set, exercise: exercise))
        }
        try context.save()
    }

    func deleteSet(id: UUID) throws {
        guard let model = try setModel(id: id) else { return }
        context.delete(model)
        try context.save()
    }

    private func exerciseModel(id: UUID) throws -> ExerciseModel? {
        var descriptor = FetchDescriptor<ExerciseModel>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func setModel(id: UUID) throws -> WorkoutSetModel? {
        var descriptor = FetchDescriptor<WorkoutSetModel>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
