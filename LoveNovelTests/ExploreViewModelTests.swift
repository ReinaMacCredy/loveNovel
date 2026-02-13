import XCTest
@testable import LoveNovel

private struct StubCatalogProvider: CatalogProviding {
    let operation: @Sendable () async throws -> HomeFeed

    func fetchHomeFeed() async throws -> HomeFeed {
        try await operation()
    }
}

final class ExploreViewModelTests: XCTestCase {
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
