import Foundation
import LoveNovelCore
import LoveNovelDomain

@MainActor
struct PreviewFeatureFactory: AppFeatureFactory {
    static let live = PreviewFeatureFactory()

    private let catalogProvider: any CatalogProviding
    private let detailProvider: any BookDetailProviding
    private let chapterTitleFormatter: any ChapterTitleFormatting

    init(
        catalogProvider: any CatalogProviding = PreviewCatalogProvider(),
        detailProvider: any BookDetailProviding = PreviewBookDetailProvider(),
        chapterTitleFormatter: any ChapterTitleFormatting = PreviewChapterTitleFormatter()
    ) {
        self.catalogProvider = catalogProvider
        self.detailProvider = detailProvider
        self.chapterTitleFormatter = chapterTitleFormatter
    }

    func makeExploreViewModel() -> ExploreViewModel {
        ExploreViewModel(
            loadHomeFeedUseCase: DefaultLoadHomeFeedUseCase(catalog: catalogProvider),
            preloadBookDetailsUseCase: DefaultPreloadBookDetailsUseCase(bookDetails: detailProvider),
            searchBooksUseCase: DefaultSearchBooksUseCase(),
            buildAllStoriesListUseCase: DefaultBuildAllStoriesListUseCase(bookDetails: detailProvider)
        )
    }

    func makeNovelDetailViewModel(book: Book) -> NovelDetailViewModel {
        NovelDetailViewModel(
            book: book,
            loadBookDetailUseCase: DefaultLoadBookDetailUseCase(detailProvider: detailProvider),
            buildDisplayedChaptersUseCase: DefaultBuildDisplayedChaptersUseCase(
                chapterTitleFormatter: chapterTitleFormatter
            ),
            sortBookCommentsUseCase: DefaultSortBookCommentsUseCase()
        )
    }

    func makeLibraryViewModel() -> LibraryViewModel {
        LibraryViewModel(
            resolveDisplayedEntriesUseCase: DefaultResolveDisplayedLibraryEntriesUseCase(),
            filterEntriesUseCase: DefaultFilterLibraryEntriesUseCase(),
            formatProgressLabelUseCase: DefaultFormatLibraryProgressLabelUseCase()
        )
    }

    func makeReaderViewModel(
        book: Book,
        initialChapter: BookChapter,
        chapterCount: Int,
        chapters: [BookChapter],
        shouldShowTutorial: Bool
    ) -> ReaderViewModel {
        ReaderViewModel(
            book: book,
            initialChapter: initialChapter,
            chapterCount: chapterCount,
            chapters: chapters,
            shouldShowTutorial: shouldShowTutorial,
            buildChapterUseCase: DefaultBuildReaderChapterUseCase(
                chapterTitleFormatter: chapterTitleFormatter
            )
        )
    }
}

private struct PreviewCatalogProvider: CatalogProviding {
    func fetchHomeFeed() async throws -> HomeFeed {
        HomeFeed(
            latest: [PreviewBooks.mutabilis, PreviewBooks.riceTea],
            featured: PreviewBooks.mutabilis,
            recommended: [PreviewBooks.riceTea, PreviewBooks.corvus],
            moreLikeThis: [PreviewBooks.corvus]
        )
    }
}

private struct PreviewBookDetailProvider: BookDetailProviding {
    func fetchDetail(for book: Book) async throws -> BookDetail {
        BookDetail(
            bookId: book.id,
            longDescription: book.summary,
            chapterCount: 24,
            viewsLabel: "8.4K",
            status: .ongoing,
            genres: ["Romance"],
            tags: ["preview"],
            uploaderName: "Preview",
            sameAuthorBooks: [],
            sameUploaderBooks: [],
            chapterTimestamp: "2026-02-24 12:00",
            reviews: [],
            comments: []
        )
    }
}

private struct PreviewChapterTitleFormatter: ChapterTitleFormatting {
    func chapterTitle(for index: Int) -> String {
        AppLocalization.format("novel_detail.chapter.title", index)
    }
}

private enum PreviewBooks {
    static let mutabilis = Book(
        id: "mutabilis",
        title: "Mutabilis",
        author: "Drew Wagar",
        summary: "Preview summary for Mutabilis.",
        rating: 4.3,
        accentHex: "FF5A2D"
    )

    static let riceTea = Book(
        id: "rice-tea",
        title: "Rice Tea",
        author: "Julien McArdle",
        summary: "Preview summary for Rice Tea.",
        rating: 4.6,
        accentHex: "1B3B72"
    )

    static let corvus = Book(
        id: "corvus",
        title: "Corvus",
        author: "M. Rivera",
        summary: "Preview summary for Corvus.",
        rating: 4.0,
        accentHex: "6D707A"
    )
}
