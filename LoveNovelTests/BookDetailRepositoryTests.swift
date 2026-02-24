import Foundation
import Testing
@testable import LoveNovelData
@testable import LoveNovelDomain

@Suite("Book detail repository tests", .tags(.repository, .fast))
struct BookDetailRepositoryTests {
    enum KnownDetailField: CaseIterable, Sendable {
        case bookID
        case chapterCount
        case viewsLabel
        case status
    }

    enum FallbackDetailField: CaseIterable, Sendable {
        case chapterCount
        case viewsLabel
        case reviews
        case comments
    }

    @Test("Fetch detail decodes known book", arguments: KnownDetailField.allCases)
    func fetchDetailDecodesKnownBook(field: KnownDetailField) async throws {
        let repository = BookDetailRepository(source: .rawData(Self.sampleJSON))

        let detail = try await repository.fetchDetail(for: Self.riceTeaBook)

        switch field {
        case .bookID:
            #expect(detail.bookId == "rice-tea")
        case .chapterCount:
            #expect(detail.chapterCount == 55)
        case .viewsLabel:
            #expect(detail.viewsLabel == "1K")
        case .status:
            #expect(detail.status == .ongoing)
        }
    }

    @Test("Fetch detail caches decoded payload across calls")
    func fetchDetailCachesDecodedPayloadAcrossCalls() async throws {
        let repository = BookDetailRepository(source: .rawData(Self.sampleJSON))

        let first = try await repository.fetchDetail(for: Self.riceTeaBook)
        let second = try await repository.fetchDetail(for: Self.mutabilisBook)

        #expect(first.bookId == "rice-tea")
        #expect(second.bookId == "mutabilis")

        #if DEBUG
        let loadCount = await repository.debugLoadCount()
        #expect(loadCount == 1)
        #endif
    }

    @Test("Fetch detail returns fallback for unknown book", arguments: FallbackDetailField.allCases)
    func fetchDetailReturnsFallbackForUnknownBook(field: FallbackDetailField) async throws {
        let repository = BookDetailRepository(source: .rawData(Self.sampleJSON))

        let detail = try await repository.fetchDetail(for: Self.unknownBook)

        #expect(detail.bookId == "unknown-id")

        switch field {
        case .chapterCount:
            #expect(detail.chapterCount == 12)
        case .viewsLabel:
            #expect(detail.viewsLabel == "0")
        case .reviews:
            #expect(detail.reviews == [])
        case .comments:
            #expect(detail.comments == [])
        }
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
