import Foundation
import LoveNovelCore

struct AppChapterTitleFormatter: ChapterTitleFormatting {
    func chapterTitle(for index: Int) -> String {
        AppLocalization.format("novel_detail.chapter.title", index)
    }
}
