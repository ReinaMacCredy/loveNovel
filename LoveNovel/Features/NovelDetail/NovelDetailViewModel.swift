import Foundation

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
    }

    enum CommentSort: String, CaseIterable, Identifiable {
        case oldest = "Oldest"
        case newest = "Newest"
        case liked = "Liked"

        var id: Self { self }
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
            errorMessage = "Could not load story details."
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
                title: "Chapter \(index)",
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

    func didTapRead() {
        alertMessage = "Reader for \(book.title) is coming in v2."
    }

    func didTapAddToLibrary() {
        alertMessage = "\(book.title) was added as a demo action."
    }

    func didTapWriteReview() {
        alertMessage = "Writing reviews is coming in v2."
    }

    func didTapSendComment() {
        let trimmedComment = draftComment.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedComment.isEmpty {
            alertMessage = "Enter a comment before sending."
            return
        }

        draftComment = ""
        alertMessage = "Comment posted as a demo action."
    }

    func dismissAlert() {
        alertMessage = nil
    }
}
