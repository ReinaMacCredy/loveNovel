import Foundation
import LoveNovelCore
import LoveNovelData
import LoveNovelDomain

struct AppContainer: Sendable, AppFeatureFactory {
    static let live = AppContainer()

    private let catalogRepository: any CatalogProviding
    private let bookDetailRepository: any BookDetailProviding
    private let chapterTitleFormatter: any ChapterTitleFormatting

    init(
        catalogRepository: any CatalogProviding = CatalogRepository(),
        bookDetailRepository: any BookDetailProviding = BookDetailRepository(),
        chapterTitleFormatter: any ChapterTitleFormatting = AppChapterTitleFormatter()
    ) {
        self.catalogRepository = catalogRepository
        self.bookDetailRepository = bookDetailRepository
        self.chapterTitleFormatter = chapterTitleFormatter
    }

    @MainActor
    func makeExploreViewModel() -> ExploreViewModel {
        ExploreViewModel(
            loadHomeFeedUseCase: DefaultLoadHomeFeedUseCase(catalog: catalogRepository),
            preloadBookDetailsUseCase: DefaultPreloadBookDetailsUseCase(bookDetails: bookDetailRepository),
            searchBooksUseCase: DefaultSearchBooksUseCase(),
            buildAllStoriesListUseCase: DefaultBuildAllStoriesListUseCase(bookDetails: bookDetailRepository)
        )
    }

    @MainActor
    func makeNovelDetailViewModel(book: Book) -> NovelDetailViewModel {
        NovelDetailViewModel(
            book: book,
            loadBookDetailUseCase: DefaultLoadBookDetailUseCase(detailProvider: bookDetailRepository),
            buildDisplayedChaptersUseCase: DefaultBuildDisplayedChaptersUseCase(
                chapterTitleFormatter: chapterTitleFormatter
            ),
            sortBookCommentsUseCase: DefaultSortBookCommentsUseCase()
        )
    }

    @MainActor
    func makeLibraryViewModel() -> LibraryViewModel {
        LibraryViewModel(
            resolveDisplayedEntriesUseCase: DefaultResolveDisplayedLibraryEntriesUseCase(),
            filterEntriesUseCase: DefaultFilterLibraryEntriesUseCase(),
            formatProgressLabelUseCase: DefaultFormatLibraryProgressLabelUseCase()
        )
    }

    @MainActor
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
