import Foundation
import Testing
@testable import LoveNovelData
@testable import LoveNovelDomain

@Suite("Catalog repository tests", .tags(.repository, .fast))
struct CatalogRepositoryTests {
    enum FeedSection: Sendable {
        case latest
        case recommended
        case moreLikeThis

        func count(in feed: HomeFeed) -> Int {
            switch self {
            case .latest:
                return feed.latest.count
            case .recommended:
                return feed.recommended.count
            case .moreLikeThis:
                return feed.moreLikeThis.count
            }
        }
    }

    @Test(
        "Decodes catalog and returns expected section counts",
        arguments: zip([
            FeedSection.latest,
            .recommended,
            .moreLikeThis
        ], [2, 1, 1])
    )
    func decodesCatalogAndReturnsExpectedSectionCounts(section: FeedSection, expectedCount: Int) async throws {
        let repository = CatalogRepository(source: .rawData(Self.sampleJSON))

        let feed = try await repository.fetchHomeFeed()

        #expect(section.count(in: feed) == expectedCount)
    }

    @Test("Decodes featured book title")
    func decodesFeaturedBookTitle() async throws {
        let repository = CatalogRepository(source: .rawData(Self.sampleJSON))

        let feed = try await repository.fetchHomeFeed()

        #expect(feed.featured.title == "Mutabilis")
    }

    @Test("Caching returns stable result across calls")
    func cachingReturnsStableResultAcrossCalls() async throws {
        let repository = CatalogRepository(source: .rawData(Self.sampleJSON))

        let first = try await repository.fetchHomeFeed()
        let second = try await repository.fetchHomeFeed()

        #expect(first == second)

        #if DEBUG
        let loadCount = await repository.debugLoadCount()
        #expect(loadCount == 1)
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
