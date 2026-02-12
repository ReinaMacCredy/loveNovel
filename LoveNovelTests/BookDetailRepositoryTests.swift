import XCTest
@testable import LoveNovel

final class BookDetailRepositoryTests: XCTestCase {
    func testFetchDetailDecodesKnownBook() async throws {
        let repository = BookDetailRepository(source: .rawData(Self.sampleJSON))

        let detail = try await repository.fetchDetail(for: Self.riceTeaBook)

        XCTAssertEqual(detail.bookId, "rice-tea")
        XCTAssertEqual(detail.chapterCount, 55)
        XCTAssertEqual(detail.viewsLabel, "1K")
        XCTAssertEqual(detail.status, .ongoing)
    }

    func testFetchDetailCachesDecodedPayloadAcrossCalls() async throws {
        let repository = BookDetailRepository(source: .rawData(Self.sampleJSON))

        let first = try await repository.fetchDetail(for: Self.riceTeaBook)
        let second = try await repository.fetchDetail(for: Self.mutabilisBook)

        XCTAssertEqual(first.bookId, "rice-tea")
        XCTAssertEqual(second.bookId, "mutabilis")

        #if DEBUG
        let loadCount = await repository.debugLoadCount()
        XCTAssertEqual(loadCount, 1)
        #endif
    }

    func testFetchDetailReturnsFallbackForUnknownBook() async throws {
        let repository = BookDetailRepository(source: .rawData(Self.sampleJSON))

        let detail = try await repository.fetchDetail(for: Self.unknownBook)

        XCTAssertEqual(detail.bookId, "unknown-id")
        XCTAssertEqual(detail.chapterCount, 12)
        XCTAssertEqual(detail.viewsLabel, "0")
        XCTAssertEqual(detail.reviews, [])
        XCTAssertEqual(detail.comments, [])
    }

    private static let riceTeaBook = Book(
        id: "rice-tea",
        title: "Rice Tea",
        author: "Julien McArdle",
        summary: "A noir story.",
        rating: 4.6,
        accentHex: "1B3B72"
    )

    private static let mutabilisBook = Book(
        id: "mutabilis",
        title: "Mutabilis",
        author: "Drew Wagar",
        summary: "A deep-space mystery.",
        rating: 4.3,
        accentHex: "FF5A2D"
    )

    private static let unknownBook = Book(
        id: "unknown-id",
        title: "Unknown",
        author: "Unknown",
        summary: "Unknown summary",
        rating: 0,
        accentHex: "000000"
    )

    private static let sampleJSON = Data(
        """
        {
          "details": [
            {
              "bookId": "rice-tea",
              "longDescription": "Detail",
              "chapterCount": 55,
              "viewsLabel": "1K",
              "status": "ongoing",
              "genres": ["Techno Thriller"],
              "tags": ["hacking"],
              "uploaderName": "KiemTienMuaSua",
              "sameAuthorBooks": [],
              "sameUploaderBooks": [],
              "chapterTimestamp": "2020-04-02 00:58",
              "reviews": [],
              "comments": []
            },
            {
              "bookId": "mutabilis",
              "longDescription": "Detail",
              "chapterCount": 42,
              "viewsLabel": "8.4K",
              "status": "ongoing",
              "genres": ["Science Fiction"],
              "tags": ["space"],
              "uploaderName": "KiemTienMuaSua",
              "sameAuthorBooks": [],
              "sameUploaderBooks": [],
              "chapterTimestamp": "2024-10-09 21:15",
              "reviews": [],
              "comments": []
            }
          ]
        }
        """.utf8
    )
}
