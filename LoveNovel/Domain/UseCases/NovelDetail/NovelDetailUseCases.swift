import Foundation
import LoveNovelCore

public enum NovelDetailChapterOrder: Sendable {
    case oldest
    case newest
}

public enum NovelDetailCommentSortOrder: Sendable {
    case oldest
    case newest
    case liked
}

public protocol LoadBookDetailUseCase: Sendable {
    func execute(for book: Book) async throws -> BookDetail
}

public struct DefaultLoadBookDetailUseCase: LoadBookDetailUseCase {
    private let detailProvider: any BookDetailProviding

    public init(detailProvider: any BookDetailProviding) {
        self.detailProvider = detailProvider
    }

    public func execute(for book: Book) async throws -> BookDetail {
        try await detailProvider.fetchDetail(for: book)
    }
}

public protocol BuildDisplayedChaptersUseCase: Sendable {
    func execute(for detail: BookDetail, order: NovelDetailChapterOrder) -> [BookChapter]
}

public struct DefaultBuildDisplayedChaptersUseCase: BuildDisplayedChaptersUseCase {
    private let chapterTitleFormatter: any ChapterTitleFormatting

    public init(chapterTitleFormatter: any ChapterTitleFormatting) {
        self.chapterTitleFormatter = chapterTitleFormatter
    }

    public func execute(for detail: BookDetail, order: NovelDetailChapterOrder) -> [BookChapter] {
        let chapters = (1...detail.chapterCount).map { index in
            BookChapter(
                id: "\(detail.bookId)-chapter-\(index)",
                index: index,
                title: chapterTitleFormatter.chapterTitle(for: index),
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

public protocol SortBookCommentsUseCase: Sendable {
    func execute(comments: [BookComment], order: NovelDetailCommentSortOrder) -> [BookComment]
}

public struct DefaultSortBookCommentsUseCase: SortBookCommentsUseCase {
    public init() {}

    public func execute(comments: [BookComment], order: NovelDetailCommentSortOrder) -> [BookComment] {
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
