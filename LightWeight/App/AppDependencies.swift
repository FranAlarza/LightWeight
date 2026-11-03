import Foundation
import SwiftData

/// Composition root: owns the live services and builds every ViewModel.
final class AppDependencies {
    let repository: TrainingRepository
    let catalog: ExerciseCatalogService
    let settings: UserSettings
    private let modelContainer: ModelContainer?

    init(
        repository: TrainingRepository,
        catalog: ExerciseCatalogService,
        settings: UserSettings,
        modelContainer: ModelContainer? = nil
    ) {
        self.repository = repository
        self.catalog = catalog
        self.settings = settings
        self.modelContainer = modelContainer
    }

    static func live() -> AppDependencies {
        do {
            let container = try SwiftDataTrainingRepository.makeContainer()
            return AppDependencies(
                repository: SwiftDataTrainingRepository(context: container.mainContext),
                catalog: WgerExerciseCatalog(),
                settings: UserSettings(),
                modelContainer: container
            )
        } catch {
            fatalError("Could not create the SwiftData container: \(error)")
        }
    }

    func makeExerciseListViewModel() -> ExerciseListViewModel {
        ExerciseListViewModel(repository: repository, settings: settings)
    }

    func makeAddExerciseViewModel() -> AddExerciseViewModel {
        AddExerciseViewModel(catalog: catalog, repository: repository)
    }

    func makeExerciseDetailViewModel(for exercise: Exercise) -> ExerciseDetailViewModel {
        ExerciseDetailViewModel(exercise: exercise, repository: repository, settings: settings)
    }

    func makeSetFormViewModel(mode: SetFormViewModel.Mode) -> SetFormViewModel {
        SetFormViewModel(mode: mode, repository: repository, settings: settings)
    }
}
