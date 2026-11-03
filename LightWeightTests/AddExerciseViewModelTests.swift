import Foundation
import Testing
@testable import LightWeight

struct AddExerciseViewModelTests {
    @Test
    func searchLoadsResults() async {
        // Given
        let viewModel = AddExerciseViewModel(catalog: StaticExerciseCatalog(), repository: InMemoryTrainingRepository())
        viewModel.query = "press"

        // When
        await viewModel.search()

        // Then
        #expect(viewModel.catalogState == .loaded)
        #expect(viewModel.results.map(\.name) == ["Press de banca", "Press militar"])
    }

    @Test
    func searchFailureMarksCatalogAsFailed() async {
        let viewModel = AddExerciseViewModel(catalog: FailingCatalog(), repository: InMemoryTrainingRepository())

        await viewModel.search()

        #expect(viewModel.catalogState == .failed)
        #expect(viewModel.results.isEmpty)
    }

    @Test
    func customCreationIsOfferedOnlyForNewNames() async {
        // Given
        let viewModel = AddExerciseViewModel(catalog: StaticExerciseCatalog(), repository: InMemoryTrainingRepository())

        // When / Then
        viewModel.query = "  "
        #expect(!viewModel.canCreateCustom)

        viewModel.query = "sentadilla"
        await viewModel.search()
        #expect(!viewModel.canCreateCustom)

        viewModel.query = "Hip thrust"
        await viewModel.search()
        #expect(viewModel.canCreateCustom)
    }

    @Test
    func addingFromCatalogKeepsTheReference() {
        // Given
        let repository = InMemoryTrainingRepository()
        let viewModel = AddExerciseViewModel(catalog: StaticExerciseCatalog(), repository: repository)
        let item = CatalogExercise(
            reference: CatalogReference(source: "wger", externalID: 73),
            name: "Press de banca",
            imageURL: URL(string: "https://wger.de/media/exercise-images/73/bench.png")
        )

        // When
        let saved = viewModel.add(item)

        // Then
        #expect(saved)
        #expect(repository.storedExercises.first?.catalogReference == item.reference)
        #expect(repository.storedExercises.first?.imageURL == item.imageURL)
    }

    @Test
    func addingCustomUsesTrimmedQuery() {
        let repository = InMemoryTrainingRepository()
        let viewModel = AddExerciseViewModel(catalog: StaticExerciseCatalog(), repository: repository)
        viewModel.query = "  Hip thrust "

        let saved = viewModel.addCustom()

        #expect(saved)
        #expect(repository.storedExercises.first?.name == "Hip thrust")
        #expect(repository.storedExercises.first?.catalogReference == nil)
    }

    @Test
    func saveFailureShowsError() {
        let viewModel = AddExerciseViewModel(catalog: StaticExerciseCatalog(), repository: FailingTrainingRepository())
        viewModel.query = "Hip thrust"

        let saved = viewModel.addCustom()

        #expect(!saved)
        #expect(viewModel.errorMessage != nil)
    }
}
