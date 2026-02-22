import Foundation
import Testing
@testable import LoveNovel

private struct StubBookDetailProvider: BookDetailProviding {
    let operation: @Sendable (Book) async throws -> BookDetail

    func fetchDetail(for book: Book) async throws -> BookDetail {
        try await operation(book)
    }
}

@MainActor
@Suite("Novel detail view model tests", .tags(.viewModel, .asyncLoad))
struct NovelDetailViewModelTests {
    @Test("Load transitions idle to loading to loaded")
    func loadTransitionsIdleToLoadingToLoaded() async {
        let gate = AsyncGate()
        let sampleDetail = Self.sampleDetail
        let provider = StubBookDetailProvider { _ in
            await gate.wait()
            return sampleDetail
        }

        let viewModel = NovelDetailViewModel(book: Self.sampleBook, detailProvider: provider)

        let loadTask = Task {
            await viewModel.load()
        }

        await gate.waitUntilArrived()
        #expect(viewModel.phase == .loading)

        await gate.open()
        await loadTask.value

        #expect(viewModel.phase == .loaded)
    }

    @Test("Load failure sets failed phase and error")
    func loadFailureSetsFailedPhaseAndError() async {
        struct TestFailure: Error {}

        let provider = StubBookDetailProvider { _ in
            throw TestFailure()
        }

        let viewModel = NovelDetailViewModel(book: Self.sampleBook, detailProvider: provider)

        await viewModel.load()

        #expect(viewModel.phase == .failed)
        let message = viewModel.errorMessage ?? ""
        #expect(message.isEmpty == false)
    }

    @Test("Chapter count for library is unavailable until detail is loaded")
    func chapterCountForLibraryIsUnavailableUntilDetailIsLoaded() async {
        let sampleDetail = Self.sampleDetail
        let provider = StubBookDetailProvider { _ in
            sampleDetail
        }

        let viewModel = NovelDetailViewModel(book: Self.sampleBook, detailProvider: provider)
        #expect(viewModel.chapterCountForLibrary == nil)

        await viewModel.load()

        #expect(viewModel.chapterCountForLibrary == sampleDetail.chapterCount)
    }

    @Test("Toggle chapter order reverses visible order")
    func toggleChapterOrderReversesVisibleOrder() async throws {
        let sampleDetail = Self.sampleDetail
        let provider = StubBookDetailProvider { _ in
            sampleDetail
        }

        let viewModel = NovelDetailViewModel(book: Self.sampleBook, detailProvider: provider)

        await viewModel.load()

        let newestFirst = try #require(viewModel.displayedChapters.first?.index)
        #expect(newestFirst == Self.sampleDetail.chapterCount)

        viewModel.toggleChapterOrder()

        let oldestFirst = try #require(viewModel.displayedChapters.first?.index)
        #expect(oldestFirst == 1)
    }

    @Test(
        "Set comment sort updates visible comments",
        arguments: zip([
            NovelDetailViewModel.CommentSort.oldest,
            .newest,
            .liked
        ], ["comment-1", "comment-2", "comment-1"])
    )
    func setCommentSortUpdatesVisibleComments(
        sort: NovelDetailViewModel.CommentSort,
        expectedFirstCommentID: String
    ) async throws {
        let sampleDetail = Self.sampleDetail
        let provider = StubBookDetailProvider { _ in
            sampleDetail
        }

        let viewModel = NovelDetailViewModel(book: Self.sampleBook, detailProvider: provider)

        await viewModel.load()
        viewModel.setCommentSort(sort)

        let firstCommentID = try #require(viewModel.displayedComments.first?.id)
        #expect(firstCommentID == expectedFirstCommentID)
    }

    @Test("Demo actions set and clear alert message")
    func demoActionsSetAndClearAlertMessage() throws {
        let sampleDetail = Self.sampleDetail
        let provider = StubBookDetailProvider { _ in
            sampleDetail
        }

        let viewModel = NovelDetailViewModel(book: Self.sampleBook, detailProvider: provider)

        viewModel.didTapRead()
        let readMessage = try #require(viewModel.alertMessage)
        #expect(readMessage.contains("Rice Tea"))

        viewModel.dismissAlert()
        #expect(viewModel.alertMessage == nil)
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
