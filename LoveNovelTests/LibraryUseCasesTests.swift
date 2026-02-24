import Foundation
import Testing
@testable import LoveNovelDomain
@testable import LoveNovelPresentation

@Suite("Library use case tests", .tags(.useCase, .fast))
struct LibraryUseCasesTests {
    @Test("Resolve displayed entries uses selected segment and sort")
    func resolveDisplayedEntriesUsesSelectedSegmentAndSort() {
        let useCase = DefaultResolveDisplayedLibraryEntriesUseCase()

        let history = useCase.execute(
            selectedSegment: .history,
            historyEntries: Self.sampleEntries,
            bookmarkEntries: Array(Self.sampleEntries.reversed()),
            historySort: .title,
            bookmarkSort: .newestSaved
        )
        #expect(history.map(\.id) == ["b", "a"])

        let bookmark = useCase.execute(
            selectedSegment: .bookmark,
            historyEntries: Self.sampleEntries,
            bookmarkEntries: Array(Self.sampleEntries.reversed()),
            historySort: .title,
            bookmarkSort: .title
        )
        #expect(bookmark.map(\.id) == ["b", "a"])
    }

    @Test("Filter entries searches title author and summary")
    func filterEntriesSearchesTitleAuthorAndSummary() {
        let useCase = DefaultFilterLibraryEntriesUseCase()

        #expect(useCase.execute(Self.sampleEntries, query: "Seeded").map(\.id) == ["a"])
        #expect(useCase.execute(Self.sampleEntries, query: "Author B").map(\.id) == ["b"])
        #expect(useCase.execute(Self.sampleEntries, query: "offline").map(\.id) == ["a"])
    }

    @Test("Format progress label includes chapter progress values")
    func formatProgressLabelIncludesChapterProgressValues() {
        let useCase = DefaultFormatLibraryProgressLabelUseCase()

        let label = useCase.execute(entry: Self.sampleEntries[0])
        #expect(label.contains("2"))
        #expect(label.contains("10"))
    }

    private static let sampleEntries: [LibraryShelfEntry] = [
        LibraryShelfEntry(
            id: "a",
            book: Book(
                id: "a",
                title: "Seeded Library Novel",
                author: "Author A",
                summary: "offline sample",
                rating: 4.5,
                accentHex: "2A5E96"
            ),
            lastReadChapter: 2,
            totalChapters: 10,
            savedAt: Date(timeIntervalSince1970: 1_700_000_000),
            lastReadAt: Date(timeIntervalSince1970: 1_700_100_000),
            isMuted: true
        ),
        LibraryShelfEntry(
            id: "b",
            book: Book(
                id: "b",
                title: "Another Story",
                author: "Author B",
                summary: "online sample",
                rating: 4.2,
                accentHex: "4B3A91"
            ),
            lastReadChapter: 3,
            totalChapters: 12,
            savedAt: Date(timeIntervalSince1970: 1_699_000_000),
            lastReadAt: Date(timeIntervalSince1970: 1_699_100_000),
            isMuted: false
        )
    ]
}
