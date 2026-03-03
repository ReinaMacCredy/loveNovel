import Foundation

public struct AppChapterTitleFormatter: ChapterTitleFormatting {
    public init() {}

    public func chapterTitle(for index: Int) -> String {
        AppLocalization.format("novel_detail.chapter.title", index)
    }
}
