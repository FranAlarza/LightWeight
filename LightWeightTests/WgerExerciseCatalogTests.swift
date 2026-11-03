import Foundation
import Testing
@testable import LightWeight

struct WgerExerciseCatalogTests {
    private let baseURL = URL(string: "https://example.test/api/v2/")!

    private static let firstPage = """
    {"count": 3, "next": "https://example.test/api/v2/exercise-translation/?page=2", "results": [
        {"exercise": 73, "name": "Press de banca", "description": "<p>ignored</p>"},
        {"exercise": 10, "name": "Sentadilla"}
    ]}
    """
    private static let secondPage = """
    {"count": 3, "next": null, "results": [
        {"exercise": 20, "name": "Curl de bíceps"},
        {"exercise": 21, "name": "curl de BÍCEPS "}
    ]}
    """

    private func makeCatalog(client: StubHTTPClient) -> WgerExerciseCatalog {
        WgerExerciseCatalog(client: client, baseURL: baseURL, languageCode: "es")
    }

    @Test
    func emptyQueryReturnsAllPagesSortedAndDeduplicated() async throws {
        // Given
        let client = StubHTTPClient(responses: [Self.firstPage, Self.secondPage])
        let catalog = makeCatalog(client: client)

        // When
        let results = try await catalog.search("")

        // Then
        #expect(results.map(\.name) == ["Curl de bíceps", "Press de banca", "Sentadilla"])
        #expect(results.first?.reference == CatalogReference(source: "wger", externalID: 20))
    }

    @Test
    func searchIgnoresCaseAndDiacritics() async throws {
        let catalog = makeCatalog(client: StubHTTPClient(responses: [Self.firstPage, Self.secondPage]))

        let results = try await catalog.search("BICEPS")

        #expect(results.map(\.name) == ["Curl de bíceps"])
    }

    @Test
    func catalogIsDownloadedOnlyOnce() async throws {
        // Given
        let client = StubHTTPClient(responses: [Self.firstPage, Self.secondPage])
        let catalog = makeCatalog(client: client)

        // When
        _ = try await catalog.search("press")
        _ = try await catalog.search("sentadilla")

        // Then
        #expect(await client.requestedURLs.count == 2)
    }

    @Test
    func requestsTheDeviceLanguage() async throws {
        let client = StubHTTPClient(responses: [Self.secondPage])
        let catalog = makeCatalog(client: client)

        _ = try await catalog.search("")

        let query = await client.requestedURLs.first?.query() ?? ""
        #expect(query.contains("language=4"))
    }

    @Test
    func serverErrorIsReported() async {
        let catalog = makeCatalog(client: StubHTTPClient(responses: ["{}"], statusCode: 503))

        await #expect(throws: CatalogError.badStatus(503)) {
            try await catalog.search("")
        }
    }

    @Test
    func failedLoadCanBeRetried() async throws {
        // Given
        let client = StubHTTPClient(responses: ["not json", Self.secondPage])
        let catalog = makeCatalog(client: client)
        _ = try? await catalog.search("")

        // When
        let results = try await catalog.search("")

        // Then
        #expect(results.count == 1)
    }

    @Test(arguments: [("es", 4), ("en", 2), ("de", 1), ("ja", 2), (nil, 2)] as [(String?, Int)])
    func languageMapping(code: String?, expected: Int) {
        #expect(WgerExerciseCatalog.languageID(for: code) == expected)
    }
}

/// Returns the queued bodies in order, one per request.
private actor StubHTTPClient: HTTPClient {
    private var responses: [String]
    private let statusCode: Int
    private(set) var requestedURLs: [URL] = []

    init(responses: [String], statusCode: Int = 200) {
        self.responses = responses
        self.statusCode = statusCode
    }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        requestedURLs.append(url)
        let body = responses.isEmpty ? "{}" : responses.removeFirst()
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (Data(body.utf8), response)
    }
}
