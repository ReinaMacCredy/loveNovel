import Foundation

struct AppContainer: Sendable {
    static let live = AppContainer()

    private let catalogRepository: any CatalogProviding
    private let bookDetailRepository: any BookDetailProviding

    init(
        catalogRepository: any CatalogProviding = CatalogRepository(),
        bookDetailRepository: any BookDetailProviding = BookDetailRepository()
    ) {
        self.catalogRepository = catalogRepository
        self.bookDetailRepository = bookDetailRepository
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
            buildDisplayedChaptersUseCase: DefaultBuildDisplayedChaptersUseCase(),
            sortBookCommentsUseCase: DefaultSortBookCommentsUseCase()
        )
    }
}
