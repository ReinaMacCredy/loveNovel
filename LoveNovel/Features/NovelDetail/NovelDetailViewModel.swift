import SwiftUI

@MainActor
final class NovelDetailViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case failed
    }

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
    }

    enum ChapterOrder {
        case oldest
        case newest
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var detail: BookDetail?
    @Published private(set) var selectedTab: Tab = .info
    @Published private(set) var commentSort: CommentSort = .newest
    @Published private(set) var chapterOrder: ChapterOrder = .newest
    @Published var draftComment: String = ""
    @Published var alertMessage: String?
    @Published private(set) var errorMessage: String?

    let book: Book

    private let detailProvider: any BookDetailProviding

    init(book: Book, detailProvider: any BookDetailProviding = BookDetailRepository()) {
        self.book = book
        self.detailProvider = detailProvider
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
            let loadedDetail = try await detailProvider.fetchDetail(for: book)

            if Task.isCancelled {
                phase = .idle
                return
            }

            detail = loadedDetail
            phase = .loaded
        } catch is CancellationError {
            phase = .idle
        } catch {
            detail = nil
            errorMessage = AppLocalization.string("Could not load story details.")
            phase = .failed
        }
    }

    func setTab(_ tab: Tab) {
        selectedTab = tab
    }

    func toggleChapterOrder() {
        chapterOrder = chapterOrder == .newest ? .oldest : .newest
    }

    func setCommentSort(_ sort: CommentSort) {
        commentSort = sort
    }

    var displayedChapters: [BookChapter] {
        guard let detail else {
            return []
        }

        let chapters = (1...detail.chapterCount).map { index in
            BookChapter(
                id: "\(detail.bookId)-chapter-\(index)",
                index: index,
                title: AppLocalization.format("novel_detail.chapter.title", index),
                timestampText: detail.chapterTimestamp
            )
        }

        switch chapterOrder {
        case .oldest:
            return chapters
        case .newest:
            return chapters.reversed()
        }
    }

    var displayedComments: [BookComment] {
        guard let detail else {
            return []
        }

        switch commentSort {
        case .oldest:
            return detail.comments.sorted { lhs, rhs in
                lhs.createdAtText < rhs.createdAtText
            }
        case .newest:
            return detail.comments.sorted { lhs, rhs in
                lhs.createdAtText > rhs.createdAtText
            }
        case .liked:
            return detail.comments.sorted { lhs, rhs in
                if lhs.likes == rhs.likes {
                    return lhs.createdAtText > rhs.createdAtText
                }
                return lhs.likes > rhs.likes
            }
        }
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
