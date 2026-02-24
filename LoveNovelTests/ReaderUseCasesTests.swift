import Testing
@testable import LoveNovelCore
@testable import LoveNovelDomain
@testable import LoveNovelPresentation

private struct StubReaderChapterFormatter: ChapterTitleFormatting {
    func chapterTitle(for index: Int) -> String {
        "Chapter \(index)"
    }
}

@Suite("Reader use case tests", .tags(.useCase, .fast))
struct ReaderUseCasesTests {
    @Test("Build reader chapter returns provided chapter when available")
    func buildReaderChapterReturnsProvidedChapterWhenAvailable() {
        let useCase = DefaultBuildReaderChapterUseCase(
            chapterTitleFormatter: StubReaderChapterFormatter()
        )
        let provided = BookChapter(
            id: "rice-tea-chapter-1",
            index: 1,
            title: "Provided title",
            timestampText: "2026-02-17 13:12"
        )

        let result = useCase.execute(
            bookID: "rice-tea",
            chapterIndex: 1,
            chapterTimestampText: "2020-04-02 00:58",
            providedChapter: provided
        )

        #expect(result == provided)
    }

    @Test("Build reader chapter falls back to formatted generated chapter")
    func buildReaderChapterFallsBackToFormattedGeneratedChapter() {
        let useCase = DefaultBuildReaderChapterUseCase(
            chapterTitleFormatter: StubReaderChapterFormatter()
        )

        let result = useCase.execute(
            bookID: "rice-tea",
            chapterIndex: 4,
            chapterTimestampText: "2020-04-02 00:58",
            providedChapter: nil
        )

        #expect(result.id == "rice-tea-chapter-4")
        #expect(result.index == 4)
        #expect(result.title == "Chapter 4")
        #expect(result.timestampText == "2020-04-02 00:58")
    }
}
