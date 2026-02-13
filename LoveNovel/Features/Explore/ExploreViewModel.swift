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

    struct AllStoriesListItem: Identifiable, Sendable, Equatable {
        let id: String
        let book: Book
        let categoryTag: String
        let rankTag: String
        let chapterCount: Int
        let viewsLabel: String
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var feed: HomeFeed?
    @Published private(set) var detailsByBookID: [String: BookDetail] = [:]
    @Published private(set) var errorMessage: String?
    @Published private(set) var selectedStoryMode: StoryMode = .all
    @Published var placeholderMessage: String?

    private let catalog: any CatalogProviding
    private let bookDetails: any BookDetailProviding
    private var pendingLoadContinuations: [CheckedContinuation<Void, Never>] = []

    init(
        catalog: any CatalogProviding = CatalogRepository(),
        bookDetails: any BookDetailProviding = BookDetailRepository()
    ) {
        self.catalog = catalog
        self.bookDetails = bookDetails
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

            let loadedDetails = await preloadDetails(for: uniqueBooks(in: loadedFeed))

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

        let books = uniqueBooks(in: feed)
        var items: [AllStoriesListItem] = []
        items.reserveCapacity(books.count)

        for (index, book) in books.enumerated() {
            if Task.isCancelled {
                return []
            }

            let rankTag = "#\(1508 + index)"

            do {
                let detail = try await bookDetails.fetchDetail(for: book)

                if Task.isCancelled {
                    return []
                }

                let categoryTag = formattedCategoryTag(from: detail.genres.first)

                items.append(
                    AllStoriesListItem(
                        id: book.id,
                        book: book,
                        categoryTag: categoryTag,
                        rankTag: rankTag,
                        chapterCount: detail.chapterCount,
                        viewsLabel: detail.viewsLabel
                    )
                )
            } catch is CancellationError {
                return []
            } catch {
                items.append(
                    AllStoriesListItem(
                        id: book.id,
                        book: book,
                        categoryTag: "#NOVEL",
                        rankTag: rankTag,
                        chapterCount: 0,
                        viewsLabel: "0"
                    )
                )
            }
        }

        return items
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

    private func formattedCategoryTag(from genre: String?) -> String {
        guard let genre = genre?.trimmingCharacters(in: .whitespacesAndNewlines), !genre.isEmpty else {
            return "#NOVEL"
        }

        return "#\(genre.uppercased())"
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

    private func preloadDetails(for books: [Book]) async -> [String: BookDetail] {
        guard !books.isEmpty else {
            return [:]
        }

        let bookDetails = self.bookDetails
        return await withTaskGroup(of: (String, BookDetail)?.self, returning: [String: BookDetail].self) { group in
            for book in books {
                group.addTask {
                    do {
                        let detail = try await bookDetails.fetchDetail(for: book)
                        return (book.id, detail)
                    } catch is CancellationError {
                        return nil
                    } catch {
                        return nil
                    }
                }
            }

            var loadedDetails: [String: BookDetail] = [:]
            loadedDetails.reserveCapacity(books.count)

            for await result in group {
                guard let (bookID, detail) = result else {
                    continue
                }
                loadedDetails[bookID] = detail
            }

            return loadedDetails
        }
    }
}
