import XCTest
@testable import LoveNovel

private struct StubCatalogProvider: CatalogProviding {
    let operation: @Sendable () async throws -> HomeFeed

    func fetchHomeFeed() async throws -> HomeFeed {
        try await operation()
    }
}

final class ExploreViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.set(AppLanguageOption.english.rawValue, forKey: AppSettingsKey.preferredLanguage)
    }

    func testLoadTransitionsIdleToLoadingToLoaded() async throws {
        let provider = StubCatalogProvider {
            try await Task.sleep(for: .milliseconds(120))
            return Self.sampleFeed
        }

        let viewModel = await MainActor.run {
            ExploreViewModel(catalog: provider)
        }

        let loadTask = Task {
            await viewModel.load()
        }

        try await Task.sleep(for: .milliseconds(20))

        let loadingPhase = await MainActor.run { viewModel.phase }
        XCTAssertEqual(loadingPhase, .loading)

        await loadTask.value

        let loadedPhase = await MainActor.run { viewModel.phase }
        XCTAssertEqual(loadedPhase, .loaded)

        let feed = await MainActor.run { viewModel.feed }
        XCTAssertEqual(feed?.featured.title, "Mutabilis")
    }

    func testLoadFailureSetsFailedPhaseAndError() async {
        struct TestFailure: Error {}

        let provider = StubCatalogProvider {
            throw TestFailure()
        }

        let viewModel = await MainActor.run {
            ExploreViewModel(catalog: provider)
        }

        await viewModel.load()

        let failedPhase = await MainActor.run { viewModel.phase }
        let message = await MainActor.run { viewModel.errorMessage }

        XCTAssertEqual(failedPhase, .failed)
        XCTAssertEqual(message, "Could not load stories.")
    }

    func testSearchBooksReturnsMatchesAcrossFieldsAndDeduplicates() async {
        let provider = StubCatalogProvider {
            Self.sampleFeed
        }

        let viewModel = await MainActor.run {
            ExploreViewModel(catalog: provider)
        }

        let titleMatches = await viewModel.searchBooks(matching: "mutabilis")
        XCTAssertEqual(titleMatches.map(\.id), ["mutabilis"])

        let authorMatches = await viewModel.searchBooks(matching: "julien")
        XCTAssertEqual(authorMatches.map(\.id), ["rice-tea"])

        let summaryMatches = await viewModel.searchBooks(matching: "underground")
        XCTAssertEqual(summaryMatches.map(\.id), ["rice-tea"])
    }

    func testSearchBooksWithWhitespaceQueryReturnsEmpty() async {
        let provider = StubCatalogProvider {
            Self.sampleFeed
        }

        let viewModel = await MainActor.run {
            ExploreViewModel(catalog: provider)
        }

        let matches = await viewModel.searchBooks(matching: "   ")
        XCTAssertTrue(matches.isEmpty)
    }

    func testSearchBooksWaitsForInFlightLoadBeforeReturningResults() async {
        let provider = StubCatalogProvider {
            try await Task.sleep(for: .milliseconds(120))
            return Self.sampleFeed
        }

        let viewModel = await MainActor.run {
            ExploreViewModel(catalog: provider)
        }

        let loadTask = Task {
            await viewModel.load()
        }
        await Task.yield()

        let loadingPhase = await MainActor.run { viewModel.phase }
        XCTAssertEqual(loadingPhase, .loading)

        let matches = await viewModel.searchBooks(matching: "mutabilis")
        XCTAssertEqual(matches.map(\.id), ["mutabilis"])

        await loadTask.value

        let finalPhase = await MainActor.run { viewModel.phase }
        XCTAssertEqual(finalPhase, .loaded)
    }

    func testSetStoryModeUpdatesSelectedStoryMode() async {
        let provider = StubCatalogProvider {
            Self.sampleFeed
        }

        let viewModel = await MainActor.run {
            ExploreViewModel(catalog: provider)
        }

        let initialMode = await MainActor.run { viewModel.selectedStoryMode }
        XCTAssertEqual(initialMode, .all)

        await MainActor.run {
            viewModel.setStoryMode(.female)
        }

        let updatedMode = await MainActor.run { viewModel.selectedStoryMode }
        XCTAssertEqual(updatedMode, .female)
    }

    private static let sampleFeed = HomeFeed(
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
}

final class LeftEdgeSwipeUpBackGestureEvaluatorTests: XCTestCase {
    private let evaluator = LeftEdgeSwipeUpBackGestureEvaluator(
        edgeWidth: 14,
        minimumVerticalTravel: 80,
        maximumHorizontalDrift: 24
    )

    func testShouldTriggerRejectsGestureStartingOutsideEdge() {
        let shouldTrigger = evaluator.shouldTrigger(
            startLocation: CGPoint(x: 15, y: 460),
            endLocation: CGPoint(x: 10, y: 340),
            translation: CGSize(width: -5, height: -120)
        )

        XCTAssertFalse(shouldTrigger)
    }

    func testShouldTriggerRejectsGestureEndingOutsideEdge() {
        let shouldTrigger = evaluator.shouldTrigger(
            startLocation: CGPoint(x: 10, y: 460),
            endLocation: CGPoint(x: 16, y: 350),
            translation: CGSize(width: 6, height: -110)
        )

        XCTAssertFalse(shouldTrigger)
    }

    func testShouldTriggerRejectsGestureWithShortVerticalTravel() {
        let shouldTrigger = evaluator.shouldTrigger(
            startLocation: CGPoint(x: 9, y: 420),
            endLocation: CGPoint(x: 7, y: 360),
            translation: CGSize(width: -2, height: -60)
        )

        XCTAssertFalse(shouldTrigger)
    }

    func testShouldTriggerRejectsGestureWithLargeHorizontalDrift() {
        let shouldTrigger = evaluator.shouldTrigger(
            startLocation: CGPoint(x: 8, y: 430),
            endLocation: CGPoint(x: 12, y: 320),
            translation: CGSize(width: 28, height: -110)
        )

        XCTAssertFalse(shouldTrigger)
    }

    func testShouldTriggerAcceptsIntentionalEdgeSwipeUp() {
        let shouldTrigger = evaluator.shouldTrigger(
            startLocation: CGPoint(x: 6, y: 430),
            endLocation: CGPoint(x: 8, y: 310),
            translation: CGSize(width: 2, height: -120)
        )

        XCTAssertTrue(shouldTrigger)
    }
}
