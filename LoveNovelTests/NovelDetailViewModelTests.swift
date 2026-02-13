import XCTest
@testable import LoveNovel

private struct StubBookDetailProvider: BookDetailProviding {
    let operation: @Sendable (Book) async throws -> BookDetail

    func fetchDetail(for book: Book) async throws -> BookDetail {
        try await operation(book)
    }
}

final class NovelDetailViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.set(AppLanguageOption.english.rawValue, forKey: AppSettingsKey.preferredLanguage)
    }

    func testLoadTransitionsIdleToLoadingToLoaded() async throws {
        let provider = StubBookDetailProvider { _ in
            try await Task.sleep(for: .milliseconds(120))
            return Self.sampleDetail
        }

        let viewModel = await MainActor.run {
            NovelDetailViewModel(book: Self.sampleBook, detailProvider: provider)
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
    }

    func testLoadFailureSetsFailedPhaseAndError() async {
        struct TestFailure: Error {}

        let provider = StubBookDetailProvider { _ in
            throw TestFailure()
        }

        let viewModel = await MainActor.run {
            NovelDetailViewModel(book: Self.sampleBook, detailProvider: provider)
        }

        await viewModel.load()

        let failedPhase = await MainActor.run { viewModel.phase }
        let message = await MainActor.run { viewModel.errorMessage }

        XCTAssertEqual(failedPhase, .failed)
        XCTAssertEqual(message, "Could not load story details.")
    }

    func testToggleChapterOrderReversesVisibleOrder() async {
        let provider = StubBookDetailProvider { _ in
            Self.sampleDetail
        }

        let viewModel = await MainActor.run {
            NovelDetailViewModel(book: Self.sampleBook, detailProvider: provider)
        }

        await viewModel.load()

        let newestFirst = await MainActor.run {
            viewModel.displayedChapters.first?.index
        }
        XCTAssertEqual(newestFirst, Self.sampleDetail.chapterCount)

        await MainActor.run {
            viewModel.toggleChapterOrder()
        }

        let oldestFirst = await MainActor.run {
            viewModel.displayedChapters.first?.index
        }
        XCTAssertEqual(oldestFirst, 1)
    }

    func testSetCommentSortUpdatesVisibleComments() async {
        let provider = StubBookDetailProvider { _ in
            Self.sampleDetail
        }

        let viewModel = await MainActor.run {
            NovelDetailViewModel(book: Self.sampleBook, detailProvider: provider)
        }

        await viewModel.load()

        await MainActor.run {
            viewModel.setCommentSort(.oldest)
        }
        let oldestFirst = await MainActor.run {
            viewModel.displayedComments.first?.id
        }
        XCTAssertEqual(oldestFirst, "comment-1")

        await MainActor.run {
            viewModel.setCommentSort(.newest)
        }
        let newestFirst = await MainActor.run {
            viewModel.displayedComments.first?.id
        }
        XCTAssertEqual(newestFirst, "comment-2")

        await MainActor.run {
            viewModel.setCommentSort(.liked)
        }
        let likedFirst = await MainActor.run {
            viewModel.displayedComments.first?.id
        }
        XCTAssertEqual(likedFirst, "comment-1")
    }

    func testDemoActionsSetAndClearAlertMessage() async {
        let provider = StubBookDetailProvider { _ in
            Self.sampleDetail
        }

        let viewModel = await MainActor.run {
            NovelDetailViewModel(book: Self.sampleBook, detailProvider: provider)
        }

        await MainActor.run {
            viewModel.didTapRead()
        }

        let readMessage = await MainActor.run { viewModel.alertMessage }
        XCTAssertEqual(readMessage, "Reader for Rice Tea is coming in v2.")

        await MainActor.run {
            viewModel.dismissAlert()
            viewModel.didTapAddToLibrary()
        }

        let addMessage = await MainActor.run { viewModel.alertMessage }
        XCTAssertEqual(addMessage, "Rice Tea was added as a demo action.")

        await MainActor.run {
            viewModel.dismissAlert()
        }

        let clearedMessage = await MainActor.run { viewModel.alertMessage }
        XCTAssertNil(clearedMessage)
    }

    private static let sampleBook = Book(
        id: "rice-tea",
        title: "Rice Tea",
        author: "Julien McArdle",
        summary: "Sample summary",
        rating: 4.6,
        accentHex: "1B3B72"
    )

    private static let sampleDetail = BookDetail(
        bookId: "rice-tea",
        longDescription: "Long description",
        chapterCount: 3,
        viewsLabel: "1K",
        status: .ongoing,
        genres: ["Techno Thriller"],
        tags: ["hacking"],
        uploaderName: "KiemTienMuaSua",
        sameAuthorBooks: [],
        sameUploaderBooks: [],
        chapterTimestamp: "2020-04-02 00:58",
        reviews: [],
        comments: [
            BookComment(
                id: "comment-1",
                author: "A",
                body: "Oldest and most liked",
                likes: 12,
                createdAtText: "2024-01-01"
            ),
            BookComment(
                id: "comment-2",
                author: "B",
                body: "Newest",
                likes: 3,
                createdAtText: "2024-06-01"
            )
        ]
    )
}
