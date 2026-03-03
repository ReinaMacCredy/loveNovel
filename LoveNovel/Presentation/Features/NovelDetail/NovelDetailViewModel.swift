import SwiftUI
import LoveNovelCore
import LoveNovelDomain

@MainActor
public final class NovelDetailViewModel: ObservableObject {
    enum Tab: String, CaseIterable, Identifiable {
        case info = "Info"
        case review = "Review"
        case comments = "Comments"
        case content = "Content"

        var id: Self { self }

        var titleKey: LocalizedStringKey {
            LocalizedStringKey(rawValue)
        }
    }

    enum CommentSort: String, CaseIterable, Identifiable {
        case oldest = "Oldest"
        case newest = "Newest"
        case liked = "Liked"

        var id: Self { self }

        var titleKey: LocalizedStringKey {
            LocalizedStringKey(rawValue)
        }

        var useCaseOrder: NovelDetailCommentSortOrder {
            switch self {
            case .oldest:
                return .oldest
            case .newest:
                return .newest
            case .liked:
                return .liked
            }
        }
    }

    enum ChapterOrder {
        case oldest
        case newest

        var useCaseOrder: NovelDetailChapterOrder {
            switch self {
            case .oldest:
                return .oldest
            case .newest:
                return .newest
            }
        }
    }

    @Published private(set) var phase: LoadPhase = .idle
    @Published private(set) var detail: BookDetail?
    @Published private(set) var selectedTab: Tab = .info
    @Published private(set) var commentSort: CommentSort = .newest
    @Published private(set) var chapterOrder: ChapterOrder = .newest
    @Published private(set) var displayedChapters: [BookChapter] = []
    @Published private(set) var displayedComments: [BookComment] = []
    @Published var draftComment: String = ""
    @Published var alertMessage: String?
    @Published private(set) var errorMessage: String?

    let book: Book

    private let loadBookDetailUseCase: any LoadBookDetailUseCase
    private let buildDisplayedChaptersUseCase: any BuildDisplayedChaptersUseCase
    private let sortBookCommentsUseCase: any SortBookCommentsUseCase

    init(
        book: Book,
        loadBookDetailUseCase: any LoadBookDetailUseCase,
        buildDisplayedChaptersUseCase: any BuildDisplayedChaptersUseCase,
        sortBookCommentsUseCase: any SortBookCommentsUseCase
    ) {
        self.book = book
        self.loadBookDetailUseCase = loadBookDetailUseCase
        self.buildDisplayedChaptersUseCase = buildDisplayedChaptersUseCase
        self.sortBookCommentsUseCase = sortBookCommentsUseCase
    }

    public static func live(
        book: Book,
        bookDetailRepository: any BookDetailProviding,
        chapterTitleFormatter: any ChapterTitleFormatting
    ) -> NovelDetailViewModel {
        NovelDetailViewModel(
            book: book,
            loadBookDetailUseCase: DefaultLoadBookDetailUseCase(detailProvider: bookDetailRepository),
            buildDisplayedChaptersUseCase: DefaultBuildDisplayedChaptersUseCase(
                chapterTitleFormatter: chapterTitleFormatter
            ),
            sortBookCommentsUseCase: DefaultSortBookCommentsUseCase()
        )
    }

    func load(force: Bool = false) async {
        if phase == .loading {
            return
        }

        if phase == .loaded && !force {
            return
        }

        phase = .loading
        errorMessage = nil

        do {
            let loadedDetail = try await loadBookDetailUseCase.execute(for: book)

            if Task.isCancelled {
                phase = .idle
                return
            }

            detail = loadedDetail
            rebuildChapters()
            rebuildComments()
            phase = .loaded
        } catch is CancellationError {
            phase = .idle
        } catch {
            detail = nil
            displayedChapters = []
            displayedComments = []
            errorMessage = AppLocalization.string("Could not load story details.")
            phase = .failed
        }
    }

    func setTab(_ tab: Tab) {
        selectedTab = tab
    }

    func toggleChapterOrder() {
        chapterOrder = chapterOrder == .newest ? .oldest : .newest
        rebuildChapters()
    }

    func setCommentSort(_ sort: CommentSort) {
        commentSort = sort
        rebuildComments()
    }

    private func rebuildChapters() {
        guard let detail else {
            displayedChapters = []
            return
        }

        displayedChapters = buildDisplayedChaptersUseCase.execute(for: detail, order: chapterOrder.useCaseOrder)
    }

    private func rebuildComments() {
        guard let detail else {
            displayedComments = []
            return
        }

        displayedComments = sortBookCommentsUseCase.execute(comments: detail.comments, order: commentSort.useCaseOrder)
    }

    var displayedReviews: [BookReview] {
        detail?.reviews ?? []
    }

    var chapterCountForLibrary: Int? {
        guard let chapterCount = detail?.chapterCount, chapterCount > 0 else {
            return nil
        }

        return chapterCount
    }

    var isReportEnabled: Bool {
        false
    }

    var reportUnavailableReason: String {
        AppLocalization.string("novel_detail.report.unavailable_reason")
    }

    var isReviewSubmissionEnabled: Bool {
        false
    }

    var reviewSubmissionUnavailableReason: String {
        AppLocalization.string("novel_detail.review.unavailable_reason")
    }

    var isCommentSubmissionEnabled: Bool {
        false
    }

    var commentSubmissionUnavailableReason: String {
        AppLocalization.string("novel_detail.comments.post.unavailable_reason")
    }

    func dismissAlert() {
        alertMessage = nil
    }
}
