import Foundation
import LoveNovelCore
import LoveNovelDomain

@MainActor
public final class ExploreViewModel: ObservableObject {
    enum StoryMode: String, CaseIterable, Identifiable {
        case all
        case male
        case female

        var id: String { rawValue }

        var headerTitle: String {
            switch self {
            case .all:
                return AppLocalization.string("All Stories")
            case .male:
                return AppLocalization.string("Male Stories")
            case .female:
                return AppLocalization.string("Female Stories")
            }
        }

        var optionTitle: String {
            switch self {
            case .all:
                return AppLocalization.string("Tất cả")
            case .male:
                return AppLocalization.string("Truyện Nam")
            case .female:
                return AppLocalization.string("Truyện Nữ")
            }
        }
    }

    typealias AllStoriesListItem = ExploreAllStoriesListItem

    @Published private(set) var phase: LoadPhase = .idle
    @Published private(set) var feed: HomeFeed?
    @Published private(set) var detailsByBookID: [String: BookDetail] = [:]
    @Published private(set) var errorMessage: String?
    @Published private(set) var selectedStoryMode: StoryMode = .all

    private let loadHomeFeedUseCase: any LoadHomeFeedUseCase
    private let preloadBookDetailsUseCase: any PreloadBookDetailsUseCase
    private let searchBooksUseCase: any SearchBooksUseCase
    private let buildAllStoriesListUseCase: any BuildAllStoriesListUseCase
    private var pendingLoadContinuations: [CheckedContinuation<Void, Never>] = []

    init(
        loadHomeFeedUseCase: any LoadHomeFeedUseCase,
        preloadBookDetailsUseCase: any PreloadBookDetailsUseCase,
        searchBooksUseCase: any SearchBooksUseCase,
        buildAllStoriesListUseCase: any BuildAllStoriesListUseCase
    ) {
        self.loadHomeFeedUseCase = loadHomeFeedUseCase
        self.preloadBookDetailsUseCase = preloadBookDetailsUseCase
        self.searchBooksUseCase = searchBooksUseCase
        self.buildAllStoriesListUseCase = buildAllStoriesListUseCase
    }

    public static func live(
        catalogRepository: any CatalogProviding,
        bookDetailRepository: any BookDetailProviding
    ) -> ExploreViewModel {
        ExploreViewModel(
            loadHomeFeedUseCase: DefaultLoadHomeFeedUseCase(catalog: catalogRepository),
            preloadBookDetailsUseCase: DefaultPreloadBookDetailsUseCase(bookDetails: bookDetailRepository),
            searchBooksUseCase: DefaultSearchBooksUseCase(),
            buildAllStoriesListUseCase: DefaultBuildAllStoriesListUseCase(bookDetails: bookDetailRepository)
        )
    }

    func load(force: Bool = false) async {
        if phase == .loaded && !force {
            return
        }

        if phase == .loading {
            await withCheckedContinuation { continuation in
                pendingLoadContinuations.append(continuation)
            }
            return
        }

        phase = .loading
        errorMessage = nil
        defer {
            resumePendingLoadContinuations()
        }

        do {
            let loadedFeed = try await loadHomeFeedUseCase.execute()

            if Task.isCancelled {
                phase = .idle
                return
            }

            let loadedDetails = await preloadBookDetailsUseCase.execute(for: ExploreBooks.uniqueBooks(in: loadedFeed))

            if Task.isCancelled {
                phase = .idle
                return
            }

            feed = loadedFeed
            detailsByBookID = loadedDetails
            phase = .loaded
        } catch is CancellationError {
            phase = .idle
        } catch {
            feed = nil
            detailsByBookID = [:]
            errorMessage = AppLocalization.string("Could not load stories.")
            phase = .failed
        }
    }

    func setStoryMode(_ storyMode: StoryMode) {
        selectedStoryMode = storyMode
    }

    func chapterCountForLibrary(for book: Book) -> Int? {
        guard let chapterCount = detailsByBookID[book.id]?.chapterCount, chapterCount > 0 else {
            return nil
        }

        return chapterCount
    }

    func searchBooks(matching query: String) async -> [Book] {
        if feed == nil {
            await load()
        }

        guard !Task.isCancelled else {
            return []
        }

        guard let feed else {
            return []
        }

        return searchBooksUseCase.execute(query: query, in: feed)
    }

    func allStoriesListItems() async -> [AllStoriesListItem] {
        if feed == nil {
            await load()
        }

        guard !Task.isCancelled else {
            return []
        }

        guard let feed else {
            return []
        }

        return await buildAllStoriesListUseCase.execute(from: feed)
    }

    private func resumePendingLoadContinuations() {
        guard !pendingLoadContinuations.isEmpty else {
            return
        }

        let continuations = pendingLoadContinuations
        pendingLoadContinuations.removeAll(keepingCapacity: true)
        continuations.forEach { continuation in
            continuation.resume()
        }
    }
}
