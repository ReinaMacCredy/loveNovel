import Foundation

@MainActor
final class ExploreViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case failed
    }

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

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var feed: HomeFeed?
    @Published private(set) var errorMessage: String?
    @Published private(set) var selectedStoryMode: StoryMode = .all
    @Published var placeholderMessage: String?

    private let catalog: any CatalogProviding
    private var pendingLoadContinuations: [CheckedContinuation<Void, Never>] = []

    init(catalog: any CatalogProviding = CatalogRepository()) {
        self.catalog = catalog
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
            let loadedFeed = try await catalog.fetchHomeFeed()

            if Task.isCancelled {
                phase = .idle
                return
            }

            feed = loadedFeed
            phase = .loaded
        } catch is CancellationError {
            phase = .idle
        } catch {
            feed = nil
            errorMessage = AppLocalization.string("Could not load stories.")
            phase = .failed
        }
    }

    func showPlaceholder(message: String) {
        placeholderMessage = message
    }

    func dismissPlaceholder() {
        placeholderMessage = nil
    }

    func setStoryMode(_ storyMode: StoryMode) {
        selectedStoryMode = storyMode
    }

    func didTapBook(_ book: Book) {
        showPlaceholder(message: AppLocalization.format("explore.placeholder.book_details", book.title))
    }

    func didTapRead(_ book: Book) {
        showPlaceholder(message: AppLocalization.format("explore.placeholder.reader_for_book", book.title))
    }

    func didTapAdd(_ book: Book) {
        showPlaceholder(message: AppLocalization.format("explore.placeholder.book_added", book.title))
    }

    func searchBooks(matching query: String) async -> [Book] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }

        if feed == nil {
            await load()
        }

        guard !Task.isCancelled else {
            return []
        }

        guard let feed else {
            return []
        }

        let normalizedQuery = normalizedSearchText(trimmedQuery)
        return uniqueBooks(in: feed).filter { book in
            normalizedSearchText(book.title).contains(normalizedQuery)
            || normalizedSearchText(book.author).contains(normalizedQuery)
            || normalizedSearchText(book.summary).contains(normalizedQuery)
        }
    }

    private func uniqueBooks(in feed: HomeFeed) -> [Book] {
        var seenBookIDs = Set<String>()
        let orderedBooks = feed.latest + [feed.featured] + feed.recommended + feed.moreLikeThis

        return orderedBooks.filter { book in
            seenBookIDs.insert(book.id).inserted
        }
    }

    private func normalizedSearchText(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
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
