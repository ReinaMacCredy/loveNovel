import CoreGraphics
import Foundation
import Testing
@testable import LoveNovel

private struct StubCatalogProvider: CatalogProviding {
    let operation: @Sendable () async throws -> HomeFeed

    func fetchHomeFeed() async throws -> HomeFeed {
        try await operation()
    }
}

private struct StubBookDetailProvider: BookDetailProviding {
    let operation: @Sendable (Book) async throws -> BookDetail

    func fetchDetail(for book: Book) async throws -> BookDetail {
        try await operation(book)
    }
}

@MainActor
@Suite("Explore view model tests", .tags(.viewModel, .asyncLoad))
struct ExploreViewModelTests {
    @Test("Load transitions idle to loading to loaded")
    func loadTransitionsIdleToLoadingToLoaded() async {
        let gate = AsyncGate()
        let provider = StubCatalogProvider {
            await gate.wait()
            return Self.sampleFeed
        }

        let viewModel = ExploreViewModel(catalog: provider)

        let loadTask = Task {
            await viewModel.load()
        }

        await gate.waitUntilArrived()
        #expect(viewModel.phase == .loading)

        await gate.open()
        await loadTask.value

        #expect(viewModel.phase == .loaded)
        #expect(viewModel.feed?.featured.title == "Mutabilis")
    }

    @Test("Load failure sets failed phase and error")
    func loadFailureSetsFailedPhaseAndError() async {
        struct TestFailure: Error {}

        let provider = StubCatalogProvider {
            throw TestFailure()
        }

        let viewModel = ExploreViewModel(catalog: provider)

        await viewModel.load()

        #expect(viewModel.phase == .failed)
        let message = viewModel.errorMessage ?? ""
        #expect(message.isEmpty == false)
    }

    @Test("Search books returns matches across fields and deduplicates")
    func searchBooksReturnsMatchesAcrossFieldsAndDeduplicates() async {
        let provider = StubCatalogProvider {
            Self.sampleFeed
        }

        let viewModel = ExploreViewModel(catalog: provider)

        let titleMatches = await viewModel.searchBooks(matching: "mutabilis")
        #expect(titleMatches.map(\.id) == ["mutabilis"])

        let authorMatches = await viewModel.searchBooks(matching: "julien")
        #expect(authorMatches.map(\.id) == ["rice-tea"])

        let summaryMatches = await viewModel.searchBooks(matching: "underground")
        #expect(summaryMatches.map(\.id) == ["rice-tea"])
    }

    @Test("Search books with whitespace query returns empty")
    func searchBooksWithWhitespaceQueryReturnsEmpty() async {
        let provider = StubCatalogProvider {
            Self.sampleFeed
        }

        let viewModel = ExploreViewModel(catalog: provider)

        let matches = await viewModel.searchBooks(matching: "   ")
        #expect(matches.isEmpty)
    }

    @Test("Search books waits for in-flight load before returning results")
    func searchBooksWaitsForInFlightLoadBeforeReturningResults() async {
        let gate = AsyncGate()
        let provider = StubCatalogProvider {
            await gate.wait()
            return Self.sampleFeed
        }

        let viewModel = ExploreViewModel(catalog: provider)

        let loadTask = Task {
            await viewModel.load()
        }

        await gate.waitUntilArrived()
        #expect(viewModel.phase == .loading)

        let searchTask = Task {
            await viewModel.searchBooks(matching: "mutabilis")
        }

        await gate.open()
        let matches = await searchTask.value
        await loadTask.value

        #expect(matches.map(\.id) == ["mutabilis"])
        #expect(viewModel.phase == .loaded)
    }

    @Test("All stories list items returns ordered deduplicated rows")
    func allStoriesListItemsReturnsOrderedDeduplicatedRows() async throws {
        let provider = StubCatalogProvider {
            Self.sampleFeed
        }

        let detailProvider = StubBookDetailProvider { book in
            Self.sampleDetail(for: book, chapterCount: book.id == "mutabilis" ? 42 : 21, genre: "Đô Thị")
        }

        let viewModel = ExploreViewModel(catalog: provider, bookDetails: detailProvider)

        let rows = await viewModel.allStoriesListItems()

        #expect(rows.map(\.book.id) == ["mutabilis", "rice-tea", "corvus"])
        let firstRow = try #require(rows.first)
        #expect(firstRow.categoryTag == "#ĐÔ THỊ")
        #expect(firstRow.rankTag == "#1508")
        #expect(firstRow.chapterCount == 42)
    }

    @Test("All stories list items falls back when detail provider fails")
    func allStoriesListItemsFallsBackWhenDetailProviderFails() async throws {
        struct TestFailure: Error {}

        let provider = StubCatalogProvider {
            Self.sampleFeed
        }

        let detailProvider = StubBookDetailProvider { _ in
            throw TestFailure()
        }

        let viewModel = ExploreViewModel(catalog: provider, bookDetails: detailProvider)

        let rows = await viewModel.allStoriesListItems()

        #expect(rows.count == 3)
        let firstRow = try #require(rows.first)
        #expect(firstRow.categoryTag == "#NOVEL")
        #expect(firstRow.chapterCount == 0)
        #expect(firstRow.viewsLabel == "0")
    }

    @Test("Set story mode updates selected story mode")
    func setStoryModeUpdatesSelectedStoryMode() {
        let provider = StubCatalogProvider {
            Self.sampleFeed
        }

        let viewModel = ExploreViewModel(catalog: provider)

        #expect(viewModel.selectedStoryMode == .all)

        viewModel.setStoryMode(.female)

        #expect(viewModel.selectedStoryMode == .female)
    }

    @Test("Chapter count for library uses preloaded details")
    func chapterCountForLibraryUsesPreloadedDetails() async {
        let provider = StubCatalogProvider {
            Self.sampleFeed
        }

        let detailProvider = StubBookDetailProvider { book in
            Self.sampleDetail(for: book, chapterCount: 77, genre: "Đô Thị")
        }

        let viewModel = ExploreViewModel(catalog: provider, bookDetails: detailProvider)
        let featuredBook = Self.sampleFeed.featured

        #expect(viewModel.chapterCountForLibrary(for: featuredBook) == nil)

        await viewModel.load()

        #expect(viewModel.chapterCountForLibrary(for: featuredBook) == 77)
    }

    @Test("Chapter count for library returns nil when detail is unavailable")
    func chapterCountForLibraryReturnsNilWhenDetailIsUnavailable() async {
        struct TestFailure: Error {}

        let provider = StubCatalogProvider {
            Self.sampleFeed
        }

        let detailProvider = StubBookDetailProvider { _ in
            throw TestFailure()
        }

        let viewModel = ExploreViewModel(catalog: provider, bookDetails: detailProvider)

        await viewModel.load()

        #expect(viewModel.chapterCountForLibrary(for: Self.sampleFeed.featured) == nil)
    }

    nonisolated private static let sampleFeed = HomeFeed(
        latest: [
            Book(
                id: "mutabilis",
                title: "Mutabilis",
                author: "Drew Wagar",
                summary: "Test summary",
                rating: 4.3,
                accentHex: "FF5A2D"
            )
        ],
        featured: Book(
            id: "mutabilis",
            title: "Mutabilis",
            author: "Drew Wagar",
            summary: "Test summary",
            rating: 4.3,
            accentHex: "FF5A2D"
        ),
        recommended: [
            Book(
                id: "rice-tea",
                title: "Rice Tea",
                author: "Julien McArdle",
                summary: "A noir story about the digital underground.",
                rating: 4.5,
                accentHex: "1B3B72"
            )
        ],
        moreLikeThis: [
            Book(
                id: "corvus",
                title: "Corvus",
                author: "M. Rivera",
                summary: "Test summary",
                rating: 4.0,
                accentHex: "6D707A"
            )
        ]
    )

    nonisolated private static func sampleDetail(for book: Book, chapterCount: Int, genre: String) -> BookDetail {
        BookDetail(
            bookId: book.id,
            longDescription: book.summary,
            chapterCount: chapterCount,
            viewsLabel: "1K",
            status: .ongoing,
            genres: [genre],
            tags: ["tag"],
            uploaderName: "Uploader",
            sameAuthorBooks: [],
            sameUploaderBooks: [],
            chapterTimestamp: "2020-04-02 00:58",
            reviews: [],
            comments: []
        )
    }
}

@Suite("Left-edge swipe-up back gesture evaluator tests", .tags(.fast, .gesture))
struct LeftEdgeSwipeUpBackGestureEvaluatorTests {
    struct GestureCase: Sendable {
        let startX: Double
        let startY: Double
        let endX: Double
        let endY: Double
        let translationWidth: Double
        let translationHeight: Double
    }

    private let evaluator = LeftEdgeSwipeUpBackGestureEvaluator(
        edgeWidth: 14,
        minimumVerticalTravel: 80,
        maximumHorizontalDrift: 24
    )

    @Test("Should trigger rejects invalid gesture vectors", arguments: [
        GestureCase(startX: 15, startY: 460, endX: 10, endY: 340, translationWidth: -5, translationHeight: -120),
        GestureCase(startX: 10, startY: 460, endX: 16, endY: 350, translationWidth: 6, translationHeight: -110),
        GestureCase(startX: 9, startY: 420, endX: 7, endY: 360, translationWidth: -2, translationHeight: -60),
        GestureCase(startX: 8, startY: 430, endX: 12, endY: 320, translationWidth: 28, translationHeight: -110)
    ])
    func shouldTriggerRejectsInvalidGestureVectors(scenario: GestureCase) {
        let shouldTrigger = evaluator.shouldTrigger(
            startLocation: CGPoint(x: scenario.startX, y: scenario.startY),
            endLocation: CGPoint(x: scenario.endX, y: scenario.endY),
            translation: CGSize(width: scenario.translationWidth, height: scenario.translationHeight)
        )

        #expect(shouldTrigger == false)
    }

    @Test("Should trigger accepts intentional edge swipe up")
    func shouldTriggerAcceptsIntentionalEdgeSwipeUp() {
        let shouldTrigger = evaluator.shouldTrigger(
            startLocation: CGPoint(x: 6, y: 430),
            endLocation: CGPoint(x: 8, y: 310),
            translation: CGSize(width: 2, height: -120)
        )

        #expect(shouldTrigger)
    }
}
