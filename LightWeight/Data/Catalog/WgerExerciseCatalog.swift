import Foundation

nonisolated enum CatalogError: Error, Equatable {
    case badStatus(Int)
}

/// Exercise catalog backed by the public wger API (https://wger.de).
///
/// wger has no text search, so the whole list for one language is downloaded once
/// and filtered locally. Exercise content is licensed CC-BY-SA 4.0 and must be attributed.
actor WgerExerciseCatalog: ExerciseCatalogService {
    static let source = "wger"
    static let attribution = "Datos de ejercicios de wger.de (CC-BY-SA 4.0)"
    static let websiteURL = URL(string: "https://wger.de")!

    private let client: HTTPClient
    private let baseURL: URL
    private let languageID: Int
    private var cachedExercises: [CatalogExercise]?
    private var inFlightLoad: Task<[CatalogExercise], Error>?

    init(
        client: HTTPClient = URLSessionHTTPClient(),
        baseURL: URL = URL(string: "https://wger.de/api/v2/")!,
        // Not `Locale.current`: it follows the app's own localizations (English only),
        // so a Spanish device would still get the English catalog.
        preferredLanguages: [String] = Locale.preferredLanguages
    ) {
        self.client = client
        self.baseURL = baseURL
        self.languageID = Self.languageID(forPreferredLanguages: preferredLanguages)
    }

    func search(_ query: String) async throws -> [CatalogExercise] {
        let exercises = try await allExercises()
        // Every word must appear, in any order: "press banca" finds "Press de Banca".
        let words = query.split(whereSeparator: \.isWhitespace)
        guard !words.isEmpty else { return exercises }
        return exercises.filter { exercise in
            words.allSatisfy { exercise.name.localizedStandardContains($0) }
        }
    }

    /// wger language id of the first preferred language wger supports, falling back to English.
    /// Accepts BCP 47 identifiers such as "es-ES".
    static func languageID(forPreferredLanguages preferredLanguages: [String]) -> Int {
        let ids = ["de": 1, "en": 2, "es": 4, "ru": 5, "nl": 6, "pt": 7, "el": 8, "cs": 9,
                   "sv": 10, "no": 11, "fr": 12, "it": 13, "pl": 14, "uk": 15, "tr": 16, "ca": 32]
        return preferredLanguages.lazy
            .compactMap { Locale.Language(identifier: $0).languageCode?.identifier }
            .compactMap { ids[$0] }
            .first ?? 2
    }

    private func allExercises() async throws -> [CatalogExercise] {
        if let cachedExercises { return cachedExercises }
        if let inFlightLoad { return try await inFlightLoad.value }

        let load = Task { try await fetchAll() }
        inFlightLoad = load
        defer { inFlightLoad = nil }
        let exercises = try await load.value
        cachedExercises = exercises
        return exercises
    }

    /// Only exercises with a main image are offered: they tend to be the common gym
    /// exercises, and the rest of the catalog is mostly niche or incomplete.
    private func fetchAll() async throws -> [CatalogExercise] {
        let translationsURL = baseURL
            .appending(path: "exercise-translation/")
            .appending(queryItems: [
                URLQueryItem(name: "language", value: String(languageID)),
                URLQueryItem(name: "limit", value: "500"),
            ])
        let imagesURL = baseURL
            .appending(path: "exerciseimage/")
            .appending(queryItems: [
                URLQueryItem(name: "is_main", value: "True"),
                URLQueryItem(name: "limit", value: "500"),
            ])

        async let translations: [WgerTranslationDTO] = fetchPages(startingAt: translationsURL)
        async let images: [WgerImageDTO] = fetchPages(startingAt: imagesURL)

        let imageURLs = Dictionary(
            try await images.map { ($0.exercise, $0.thumbnails?.small ?? $0.image) },
            uniquingKeysWith: { first, _ in first }
        )

        // wger has a few duplicated names; keep the first one so the list is not confusing.
        var seenNames = Set<String>()
        return try await translations
            .compactMap { translation -> CatalogExercise? in
                guard let imageURL = imageURLs[translation.exercise] else { return nil }
                return CatalogExercise(
                    reference: CatalogReference(source: Self.source, externalID: translation.exercise),
                    name: translation.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    imageURL: imageURL
                )
            }
            .filter { !$0.name.isEmpty && seenNames.insert($0.name.lowercased()).inserted }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private nonisolated func fetchPages<Item: Decodable & Sendable>(startingAt url: URL) async throws -> [Item] {
        var nextURL: URL? = url
        var items: [Item] = []

        while let url = nextURL {
            try Task.checkCancellation()
            let (data, response) = try await client.data(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw CatalogError.badStatus(http.statusCode)
            }
            let page = try JSONDecoder().decode(WgerPageDTO<Item>.self, from: data)
            items += page.results
            nextURL = page.next
        }
        return items
    }
}

nonisolated struct WgerPageDTO<Item: Decodable & Sendable>: Decodable, Sendable {
    let next: URL?
    let results: [Item]
}

nonisolated struct WgerTranslationDTO: Decodable, Sendable {
    let exercise: Int
    let name: String
}

nonisolated struct WgerImageDTO: Decodable, Sendable {
    struct Thumbnails: Decodable, Sendable {
        let small: URL?
    }

    let exercise: Int
    let image: URL
    let thumbnails: Thumbnails?
}
