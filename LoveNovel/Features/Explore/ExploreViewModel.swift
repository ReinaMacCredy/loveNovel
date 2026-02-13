import Foundation

@MainActor
final class ExploreViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case failed
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var feed: HomeFeed?
    @Published private(set) var errorMessage: String?
    @Published var placeholderMessage: String?

    private let catalog: any CatalogProviding

    init(catalog: any CatalogProviding = CatalogRepository()) {
        self.catalog = catalog
    }

    func load(force: Bool = false) async {
        if phase == .loading {
            return
        }

        if phase == .loaded && !force {
            return
        }

        phase = .loading
        errorMessage = nil

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
            errorMessage = "Could not load stories."
            phase = .failed
        }
    }

    func showPlaceholder(message: String) {
        placeholderMessage = message
    }

    func dismissPlaceholder() {
        placeholderMessage = nil
    }

    func didTapBook(_ book: Book) {
        showPlaceholder(message: "\(book.title) details are coming in v2.")
    }

    func didTapRead(_ book: Book) {
        showPlaceholder(message: "Reader for \(book.title) is coming in v2.")
    }

    func didTapAdd(_ book: Book) {
        showPlaceholder(message: "\(book.title) was added as a demo action.")
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
}
