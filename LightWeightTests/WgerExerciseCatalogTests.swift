import Foundation
import Testing
@testable import LightWeight

struct WgerExerciseCatalogTests {
    private let baseURL = URL(string: "https://example.test/api/v2/")!

    private static let translationsFirstPage = """
    {"count": 5, "next": "https://example.test/api/v2/exercise-translation/?page=2", "results": [
        {"exercise": 73, "name": "Press de banca", "description": "<p>ignored</p>"},
        {"exercise": 10, "name": "Sentadilla"},
        {"exercise": 99, "name": "Ejercicio sin imagen"}
    ]}
    """
    private static let translationsSecondPage = """
    {"count": 5, "next": null, "results": [
        {"exercise": 20, "name": "Curl de bíceps"},
        {"exercise": 21, "name": "curl de BÍCEPS "}
    ]}
    """
    private static let images = """
    {"count": 4, "next": null, "results": [
        {"exercise": 73, "image": "https://example.test/bench.png", "thumbnails": {"small": "https://example.test/bench-small.png"}},
        {"exercise": 10, "image": "https://example.test/squat.png", "thumbnails": null},
        {"exercise": 20, "image": "https://example.test/curl.png", "thumbnails": {"small": "https://example.test/curl-small.png"}},
        {"exercise": 21, "image": "https://example.test/curl2.png", "thumbnails": {"small": "https://example.test/curl2-small.png"}}
    ]}
    """

    private static let exercises = """
    {"count": 4, "next": null, "results": [
        {"id": 73, "category": 11},
        {"id": 10, "category": 9},
        {"id": 20, "category": 8},
        {"id": 21, "category": null}
    ]}
    """

    private static let defaultRoutes = [
        "exercise-translation": [translationsFirstPage, translationsSecondPage],
        "exerciseimage": [images],
        "/exercise/": [exercises],
    ]

    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 24 * 60 * 60

    private func makeCatalog(
        client: StubHTTPClient,
        cache: InMemoryCatalogCacheStore = InMemoryCatalogCacheStore()
    ) -> WgerExerciseCatalog {
        WgerExerciseCatalog(
            client: client,
            baseURL: baseURL,
            preferredLanguages: ["es-ES"],
            cacheStore: cache,
            now: { [now] in now }
        )
    }

    private func snapshot(ageInDays: Double, languageID: Int = 4) -> CatalogSnapshot {
        CatalogSnapshot(
            fetchedAt: now.addingTimeInterval(-ageInDays * day),
            languageID: languageID,
            exercises: [CatalogExercise(reference: CatalogReference(source: "wger", externalID: 1), name: "Desde caché", muscleGroup: .back)]
        )
    }

    @Test
    func emptyQueryReturnsExercisesWithImagesSortedAndDeduplicated() async throws {
        // Given
        let catalog = makeCatalog(client: StubHTTPClient(routes: Self.defaultRoutes))

        // When
        let results = try await catalog.search("")

        // Then
        #expect(results.map(\.name) == ["Curl de bíceps", "Press de banca", "Sentadilla"])
        #expect(results.first?.reference == CatalogReference(source: "wger", externalID: 20))
    }

    @Test
    func exercisesWithoutImageAreLeftOut() async throws {
        let catalog = makeCatalog(client: StubHTTPClient(routes: Self.defaultRoutes))

        let results = try await catalog.search("sin imagen")

        #expect(results.isEmpty)
    }

    @Test
    func imageUsesSmallThumbnailWithFallbackToOriginal() async throws {
        // Given
        let catalog = makeCatalog(client: StubHTTPClient(routes: Self.defaultRoutes))

        // When
        let results = try await catalog.search("")

        // Then
        let images = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0.imageURL) })
        #expect(images[73] == URL(string: "https://example.test/bench-small.png"))
        #expect(images[10] == URL(string: "https://example.test/squat.png"))
    }

    @Test
    func exercisesGetTheMuscleGroupOfTheirCategory() async throws {
        // Given
        let catalog = makeCatalog(client: StubHTTPClient(routes: Self.defaultRoutes))

        // When
        let results = try await catalog.search("")

        // Then
        let groups = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0.muscleGroup) })
        #expect(groups == [73: .chest, 10: .legs, 20: .arms])
    }

    @Test(arguments: [(8, MuscleGroup.arms), (9, .legs), (10, .abs), (11, .chest), (12, .back), (13, .shoulders), (14, .calves), (15, .cardio), (99, .other)])
    func categoryMapping(categoryID: Int, expected: MuscleGroup) {
        #expect(WgerExerciseCatalog.muscleGroup(forCategoryID: categoryID) == expected)
    }

    @Test
    func searchIgnoresCaseAndDiacritics() async throws {
        let catalog = makeCatalog(client: StubHTTPClient(routes: Self.defaultRoutes))

        let results = try await catalog.search("BICEPS")

        #expect(results.map(\.name) == ["Curl de bíceps"])
    }

    @Test
    func searchMatchesEveryWordInAnyOrder() async throws {
        let catalog = makeCatalog(client: StubHTTPClient(routes: Self.defaultRoutes))

        let results = try await catalog.search("  banca   PRESS ")

        #expect(results.map(\.name) == ["Press de banca"])
    }

    @Test
    func catalogIsDownloadedOnlyOnce() async throws {
        // Given
        let client = StubHTTPClient(routes: Self.defaultRoutes)
        let catalog = makeCatalog(client: client)

        // When
        _ = try await catalog.search("press")
        _ = try await catalog.search("sentadilla")

        // Then: two translation pages, one image page and one exercise page
        #expect(await client.requestedURLs.count == 4)
    }

    @Test
    func requestsTheDeviceLanguageAndMainImages() async throws {
        let client = StubHTTPClient(routes: Self.defaultRoutes)
        let catalog = makeCatalog(client: client)

        _ = try await catalog.search("")

        let queries = await client.requestedURLs.compactMap { $0.query() }
        #expect(queries.contains { $0.contains("language=4") })
        #expect(queries.contains { $0.contains("is_main=True") })
    }

    @Test
    func serverErrorIsReported() async {
        let catalog = makeCatalog(client: StubHTTPClient(routes: Self.defaultRoutes, statusCode: 503))

        await #expect(throws: CatalogError.badStatus(503)) {
            try await catalog.search("")
        }
    }

    @Test
    func failedLoadCanBeRetried() async throws {
        // Given
        let client = StubHTTPClient(routes: [
            "exercise-translation": ["not json", Self.translationsSecondPage],
            "exerciseimage": [Self.images, Self.images],
            "/exercise/": [Self.exercises, Self.exercises],
        ])
        let catalog = makeCatalog(client: client)
        _ = try? await catalog.search("")

        // When
        let results = try await catalog.search("")

        // Then
        #expect(results.count == 1)
    }

    @Test
    func freshCacheIsUsedWithoutNetwork() async throws {
        // Given
        let client = StubHTTPClient(routes: Self.defaultRoutes)
        let catalog = makeCatalog(client: client, cache: InMemoryCatalogCacheStore(snapshot(ageInDays: 14)))

        // When
        let results = try await catalog.search("")

        // Then
        #expect(results.map(\.name) == ["Desde caché"])
        #expect(await client.requestedURLs.isEmpty)
    }

    @Test
    func expiredCacheIsRefreshedAndSaved() async throws {
        // Given
        let cache = InMemoryCatalogCacheStore(snapshot(ageInDays: 16))
        let catalog = makeCatalog(client: StubHTTPClient(routes: Self.defaultRoutes), cache: cache)

        // When
        let results = try await catalog.search("")

        // Then
        #expect(results.count == 3)
        let saved = await cache.snapshot
        #expect(saved?.fetchedAt == now)
        #expect(saved?.languageID == 4)
        #expect(saved?.exercises == results)
    }

    @Test
    func cacheInAnotherLanguageIsIgnored() async throws {
        let client = StubHTTPClient(routes: Self.defaultRoutes)
        let catalog = makeCatalog(client: client, cache: InMemoryCatalogCacheStore(snapshot(ageInDays: 1, languageID: 2)))

        let results = try await catalog.search("")

        #expect(results.count == 3)
        #expect(await !client.requestedURLs.isEmpty)
    }

    @Test
    func expiredCacheIsUsedWhenDownloadFails() async throws {
        // Given
        let catalog = makeCatalog(
            client: StubHTTPClient(routes: Self.defaultRoutes, statusCode: 503),
            cache: InMemoryCatalogCacheStore(snapshot(ageInDays: 40))
        )

        // When
        let results = try await catalog.search("")

        // Then
        #expect(results.map(\.name) == ["Desde caché"])
    }

    @Test
    func prefetchLoadsTheCatalogOnceForLaterSearches() async throws {
        // Given
        let client = StubHTTPClient(routes: Self.defaultRoutes)
        let catalog = makeCatalog(client: client)

        // When
        await catalog.prefetch()
        let results = try await catalog.search("press")

        // Then
        #expect(results.map(\.name) == ["Press de banca"])
        #expect(await client.requestedURLs.count == 4)
    }

    @Test
    func failedPrefetchLetsSearchRetry() async throws {
        // Given
        let client = StubHTTPClient(routes: [
            "exercise-translation": ["not json", Self.translationsSecondPage],
            "exerciseimage": [Self.images, Self.images],
            "/exercise/": [Self.exercises, Self.exercises],
        ])
        let catalog = makeCatalog(client: client)

        // When
        await catalog.prefetch()
        let results = try await catalog.search("")

        // Then
        #expect(results.count == 1)
    }

    @Test(arguments: [
        (["es-ES"], 4),
        (["es-419", "en-US"], 4),
        (["en-US", "es-ES"], 2),
        (["ja-JP", "fr-FR"], 12),
        (["ja-JP"], 2),
        ([], 2),
    ] as [([String], Int)])
    func languageMapping(preferredLanguages: [String], expected: Int) {
        #expect(WgerExerciseCatalog.languageID(forPreferredLanguages: preferredLanguages) == expected)
    }
}

/// Answers each request with the next queued body for the first route its path contains.
private actor StubHTTPClient: HTTPClient {
    private var routes: [String: [String]]
    private let statusCode: Int
    private(set) var requestedURLs: [URL] = []

    init(routes: [String: [String]], statusCode: Int = 200) {
        self.routes = routes
        self.statusCode = statusCode
    }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        requestedURLs.append(url)
        let key = routes.keys.first { url.path().contains($0) }
        var body = "{}"
        if let key, var queue = routes[key], !queue.isEmpty {
            body = queue.removeFirst()
            routes[key] = queue
        }
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (Data(body.utf8), response)
    }
}

private actor InMemoryCatalogCacheStore: CatalogCacheStore {
    private(set) var snapshot: CatalogSnapshot?

    init(_ snapshot: CatalogSnapshot? = nil) {
        self.snapshot = snapshot
    }

    func load() async -> CatalogSnapshot? { snapshot }

    func save(_ snapshot: CatalogSnapshot) async {
        self.snapshot = snapshot
    }
}
