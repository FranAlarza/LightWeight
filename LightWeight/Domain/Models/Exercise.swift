import Foundation

/// Link between a local exercise and the catalog entry it was created from.
nonisolated struct CatalogReference: Codable, Hashable, Sendable {
    var source: String
    var externalID: Int
}

nonisolated struct Exercise: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var muscleGroup: MuscleGroup
    var catalogReference: CatalogReference?
    var imageURL: URL?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: MuscleGroup = .other,
        catalogReference: CatalogReference? = nil,
        imageURL: URL? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.catalogReference = catalogReference
        self.imageURL = imageURL
        self.createdAt = createdAt
    }
}

nonisolated struct CatalogExercise: Codable, Identifiable, Hashable, Sendable {
    let reference: CatalogReference
    let name: String
    var muscleGroup: MuscleGroup = .other
    var imageURL: URL?

    var id: Int { reference.externalID }
}
