import Foundation

enum NovelDetailChapterOrder: Sendable {
    case oldest
    case newest
}

enum NovelDetailCommentSortOrder: Sendable {
    case oldest
    case newest
    case liked
}

protocol LoadBookDetailUseCase: Sendable {
    func execute(for book: Book) async throws -> BookDetail
}

struct DefaultLoadBookDetailUseCase: LoadBookDetailUseCase {
    private let detailProvider: any BookDetailProviding

    init(detailProvider: any BookDetailProviding) {
        self.detailProvider = detailProvider
    }

    func execute(for book: Book) async throws -> BookDetail {
        try await detailProvider.fetchDetail(for: book)
    }
}

protocol BuildDisplayedChaptersUseCase: Sendable {
    func execute(for detail: BookDetail, order: NovelDetailChapterOrder) -> [BookChapter]
}

struct DefaultBuildDisplayedChaptersUseCase: BuildDisplayedChaptersUseCase {
    func execute(for detail: BookDetail, order: NovelDetailChapterOrder) -> [BookChapter] {
        let chapters = (1...detail.chapterCount).map { index in
            BookChapter(
                id: "\(detail.bookId)-chapter-\(index)",
                index: index,
                title: AppLocalization.format("novel_detail.chapter.title", index),
                timestampText: detail.chapterTimestamp
            )
        }

        switch order {
        case .oldest:
            return chapters
        case .newest:
            return chapters.reversed()
        }
    }
}

protocol SortBookCommentsUseCase: Sendable {
    func execute(comments: [BookComment], order: NovelDetailCommentSortOrder) -> [BookComment]
}

struct DefaultSortBookCommentsUseCase: SortBookCommentsUseCase {
    func execute(comments: [BookComment], order: NovelDetailCommentSortOrder) -> [BookComment] {
        switch order {
        case .oldest:
            return comments.sorted { lhs, rhs in
                lhs.createdAtText < rhs.createdAtText
            }
        case .newest:
            return comments.sorted { lhs, rhs in
                lhs.createdAtText > rhs.createdAtText
            }
        case .liked:
            return comments.sorted { lhs, rhs in
                if lhs.likes == rhs.likes {
                    return lhs.createdAtText > rhs.createdAtText
                }

                return lhs.likes > rhs.likes
            }
        }
    }
}
