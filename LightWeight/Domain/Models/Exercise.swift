import Foundation

/// Link between a local exercise and the catalog entry it was created from.
nonisolated struct CatalogReference: Hashable, Sendable {
    var source: String
    var externalID: Int
}

nonisolated struct Exercise: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var catalogReference: CatalogReference?
    var imageURL: URL?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        catalogReference: CatalogReference? = nil,
        imageURL: URL? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.catalogReference = catalogReference
        self.imageURL = imageURL
        self.createdAt = createdAt
    }
}

nonisolated struct CatalogExercise: Identifiable, Hashable, Sendable {
    let reference: CatalogReference
    let name: String
    var imageURL: URL?

    var id: Int { reference.externalID }
}
