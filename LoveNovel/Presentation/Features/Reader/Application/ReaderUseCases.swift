import Foundation
import LoveNovelCore
import LoveNovelDomain

protocol BuildReaderChapterUseCase: Sendable {
    func execute(
        bookID: String,
        chapterIndex: Int,
        chapterTimestampText: String,
        providedChapter: BookChapter?
    ) -> BookChapter
}

struct DefaultBuildReaderChapterUseCase: BuildReaderChapterUseCase {
    private let chapterTitleFormatter: any ChapterTitleFormatting

    init(chapterTitleFormatter: any ChapterTitleFormatting) {
        self.chapterTitleFormatter = chapterTitleFormatter
    }

    func execute(
        bookID: String,
        chapterIndex: Int,
        chapterTimestampText: String,
        providedChapter: BookChapter?
    ) -> BookChapter {
        if let providedChapter {
            return providedChapter
        }

        return BookChapter(
            id: "\(bookID)-chapter-\(chapterIndex)",
            index: chapterIndex,
            title: chapterTitleFormatter.chapterTitle(for: chapterIndex),
            timestampText: chapterTimestampText
        )
    }
}
