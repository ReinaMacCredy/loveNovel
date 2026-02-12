import XCTest
@testable import LoveNovel

final class CatalogRepositoryTests: XCTestCase {
    func testDecodesCatalogAndReturnsExpectedCounts() async throws {
        let repository = CatalogRepository(source: .rawData(Self.sampleJSON))

        let feed = try await repository.fetchHomeFeed()

        XCTAssertEqual(feed.latest.count, 2)
        XCTAssertEqual(feed.recommended.count, 1)
        XCTAssertEqual(feed.moreLikeThis.count, 1)
        XCTAssertEqual(feed.featured.title, "Mutabilis")
    }

    func testCachingReturnsStableResultAcrossCalls() async throws {
        let repository = CatalogRepository(source: .rawData(Self.sampleJSON))

        let first = try await repository.fetchHomeFeed()
        let second = try await repository.fetchHomeFeed()

        XCTAssertEqual(first, second)

        #if DEBUG
        let loadCount = await repository.debugLoadCount()
        XCTAssertEqual(loadCount, 1)
        #endif
    }

    private static let sampleJSON = Data(
        """
        {
          "latest": [
            {
              "id": "mutabilis",
              "title": "Mutabilis",
              "author": "Drew Wagar",
              "summary": "Test summary",
              "rating": 4.3,
              "accentHex": "FF5A2D"
            },
            {
              "id": "rice-tea",
              "title": "Rice Tea",
              "author": "Julien McArdle",
              "summary": "Test summary",
              "rating": 4.5,
              "accentHex": "1B3B72"
            }
          ],
          "featured": {
            "id": "mutabilis",
            "title": "Mutabilis",
            "author": "Drew Wagar",
            "summary": "Test summary",
            "rating": 4.3,
            "accentHex": "FF5A2D"
          },
          "recommended": [
            {
              "id": "derelict",
              "title": "Derelict",
              "author": "Albert Berg",
              "summary": "Test summary",
              "rating": 4.1,
              "accentHex": "C3321F"
            }
          ],
          "moreLikeThis": [
            {
              "id": "corvus",
              "title": "Corvus",
              "author": "M. Rivera",
              "summary": "Test summary",
              "rating": 4.0,
              "accentHex": "6D707A"
            }
          ]
        }
        """.utf8
    )
}
