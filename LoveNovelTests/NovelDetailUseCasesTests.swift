import Testing
@testable import LoveNovelCore
@testable import LoveNovelDomain

private struct StubChapterTitleFormatter: ChapterTitleFormatting {
    func chapterTitle(for index: Int) -> String {
        "CH-\(index)"
    }
}

@Suite("Novel detail use case tests", .tags(.useCase, .fast))
struct NovelDetailUseCasesTests {
    @Test(
        "Build displayed chapters respects order and formatter",
        arguments: zip(
            [NovelDetailChapterOrder.oldest, .newest],
            [(1, "CH-1"), (3, "CH-3")]
        )
    )
    func buildDisplayedChaptersRespectsOrderAndFormatter(
        order: NovelDetailChapterOrder,
        expectedFirstChapter: (index: Int, title: String)
    ) throws {
        let useCase = DefaultBuildDisplayedChaptersUseCase(
            chapterTitleFormatter: StubChapterTitleFormatter()
        )

        let chapters = useCase.execute(for: Self.sampleDetail, order: order)

        #expect(chapters.count == Self.sampleDetail.chapterCount)
        let firstChapter = try #require(chapters.first)
        #expect(firstChapter.index == expectedFirstChapter.index)
        #expect(firstChapter.title == expectedFirstChapter.title)
    }

    private static let sampleDetail = BookDetail(
        bookId: "rice-tea",
        longDescription: "Long description",
        chapterCount: 3,
        viewsLabel: "1K",
        status: .ongoing,
        genres: ["Thriller"],
        tags: ["sample"],
        uploaderName: "Community",
        sameAuthorBooks: [],
        sameUploaderBooks: [],
        chapterTimestamp: "2020-04-02 00:58",
        reviews: [],
        comments: []
    )
}
