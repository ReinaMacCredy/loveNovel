import Foundation
import LoveNovelCore
import LoveNovelData
import LoveNovelDomain
import LoveNovelPresentation

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
        ExploreViewModel.live(
            catalogRepository: catalogRepository,
            bookDetailRepository: bookDetailRepository
        )
    }

    @MainActor
    func makeNovelDetailViewModel(book: Book) -> NovelDetailViewModel {
        NovelDetailViewModel.live(
            book: book,
            bookDetailRepository: bookDetailRepository,
            chapterTitleFormatter: chapterTitleFormatter
        )
    }

    @MainActor
    func makeLibraryViewModel() -> LibraryViewModel {
        LibraryViewModel.live()
    }

    @MainActor
    func makeReaderViewModel(
        book: Book,
        initialChapter: BookChapter,
        chapterCount: Int,
        chapters: [BookChapter],
        shouldShowTutorial: Bool
    ) -> ReaderViewModel {
        ReaderViewModel.live(
            book: book,
            initialChapter: initialChapter,
            chapterCount: chapterCount,
            chapters: chapters,
            shouldShowTutorial: shouldShowTutorial,
            chapterTitleFormatter: chapterTitleFormatter
        )
    }
}
