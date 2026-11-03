import Foundation
import Testing
@testable import LightWeight

struct FileCatalogCacheStoreTests {
    private let fileURL = URL.temporaryDirectory.appending(path: "catalog-\(UUID().uuidString).json")

    @Test
    func savedSnapshotLoadsBack() async {
        // Given
        let store = FileCatalogCacheStore(fileURL: fileURL)
        let snapshot = CatalogSnapshot(
            fetchedAt: Date(timeIntervalSince1970: 1_800_000_000),
            languageID: 4,
            exercises: [CatalogExercise(
                reference: CatalogReference(source: "wger", externalID: 73),
                name: "Press de Banca",
                muscleGroup: .chest,
                imageURL: URL(string: "https://wger.de/bench.png")
            )]
        )

        // When
        await store.save(snapshot)
        let loaded = await store.load()

        // Then
        #expect(loaded == snapshot)
        try? FileManager.default.removeItem(at: fileURL)
    }

    @Test
    func missingOrCorruptFileLoadsNothing() async throws {
        let store = FileCatalogCacheStore(fileURL: fileURL)
        #expect(await store.load() == nil)

        try Data("not json".utf8).write(to: fileURL)
        #expect(await store.load() == nil)
        try? FileManager.default.removeItem(at: fileURL)
    }
}
