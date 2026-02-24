import Foundation

public protocol ChapterTitleFormatting: Sendable {
    func chapterTitle(for index: Int) -> String
}
