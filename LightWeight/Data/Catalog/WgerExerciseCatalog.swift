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
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return exercises }
        return exercises.filter { $0.name.localizedStandardContains(trimmed) }
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

    private func fetchAll() async throws -> [CatalogExercise] {
        var nextURL: URL? = baseURL
            .appending(path: "exercise-translation/")
            .appending(queryItems: [
                URLQueryItem(name: "language", value: String(languageID)),
                URLQueryItem(name: "limit", value: "500"),
            ])
        var translations: [WgerTranslationDTO] = []

        while let url = nextURL {
            try Task.checkCancellation()
            let (data, response) = try await client.data(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw CatalogError.badStatus(http.statusCode)
            }
            let page = try JSONDecoder().decode(WgerPageDTO<WgerTranslationDTO>.self, from: data)
            translations += page.results
            nextURL = page.next
        }

        // wger has a few duplicated names; keep the first one so the list is not confusing.
        var seenNames = Set<String>()
        return translations
            .map { CatalogExercise(reference: CatalogReference(source: Self.source, externalID: $0.exercise), name: $0.name.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.name.isEmpty && seenNames.insert($0.name.lowercased()).inserted }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
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
