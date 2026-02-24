import Foundation

public struct ExploreAllStoriesListItem: Identifiable, Sendable, Equatable {
    public let id: String
    public let book: Book
    public let categoryTag: String
    public let rankTag: String
    public let chapterCount: Int
    public let viewsLabel: String

    public init(
        id: String,
        book: Book,
        categoryTag: String,
        rankTag: String,
        chapterCount: Int,
        viewsLabel: String
    ) {
        self.id = id
        self.book = book
        self.categoryTag = categoryTag
        self.rankTag = rankTag
        self.chapterCount = chapterCount
        self.viewsLabel = viewsLabel
    }
}

public protocol LoadHomeFeedUseCase: Sendable {
    func execute() async throws -> HomeFeed
}

public struct DefaultLoadHomeFeedUseCase: LoadHomeFeedUseCase {
    private let catalog: any CatalogProviding

    public init(catalog: any CatalogProviding) {
        self.catalog = catalog
    }

    public func execute() async throws -> HomeFeed {
        try await catalog.fetchHomeFeed()
    }
}

public protocol PreloadBookDetailsUseCase: Sendable {
    func execute(for books: [Book]) async -> [String: BookDetail]
}

public struct DefaultPreloadBookDetailsUseCase: PreloadBookDetailsUseCase {
    private let bookDetails: any BookDetailProviding

    public init(bookDetails: any BookDetailProviding) {
        self.bookDetails = bookDetails
    }

    public func execute(for books: [Book]) async -> [String: BookDetail] {
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

public protocol SearchBooksUseCase: Sendable {
    func execute(query: String, in feed: HomeFeed) -> [Book]
}

public struct DefaultSearchBooksUseCase: SearchBooksUseCase {
    public init() {}

    public func execute(query: String, in feed: HomeFeed) -> [Book] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }

        let normalizedQuery = normalizedSearchText(trimmedQuery)
        return ExploreBooks.uniqueBooks(in: feed).filter { book in
            normalizedSearchText(book.title).contains(normalizedQuery)
            || normalizedSearchText(book.author).contains(normalizedQuery)
            || normalizedSearchText(book.summary).contains(normalizedQuery)
        }
    }

    private func normalizedSearchText(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

public protocol BuildAllStoriesListUseCase: Sendable {
    func execute(from feed: HomeFeed) async -> [ExploreAllStoriesListItem]
}

public struct DefaultBuildAllStoriesListUseCase: BuildAllStoriesListUseCase {
    private let bookDetails: any BookDetailProviding

    public init(bookDetails: any BookDetailProviding) {
        self.bookDetails = bookDetails
    }

    public func execute(from feed: HomeFeed) async -> [ExploreAllStoriesListItem] {
        let books = ExploreBooks.uniqueBooks(in: feed)
        var items: [ExploreAllStoriesListItem] = []
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

                items.append(
                    ExploreAllStoriesListItem(
                        id: book.id,
                        book: book,
                        categoryTag: formattedCategoryTag(from: detail.genres.first),
                        rankTag: rankTag,
                        chapterCount: detail.chapterCount,
                        viewsLabel: detail.viewsLabel
                    )
                )
            } catch is CancellationError {
                return []
            } catch {
                items.append(
                    ExploreAllStoriesListItem(
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

    private func formattedCategoryTag(from genre: String?) -> String {
        guard let genre = genre?.trimmingCharacters(in: .whitespacesAndNewlines), !genre.isEmpty else {
            return "#NOVEL"
        }

        return "#\(genre.uppercased())"
    }
}

public enum ExploreBooks {
    public static func uniqueBooks(in feed: HomeFeed) -> [Book] {
        var seenBookIDs = Set<String>()
        let orderedBooks = feed.latest + [feed.featured] + feed.recommended + feed.moreLikeThis

        return orderedBooks.filter { book in
            seenBookIDs.insert(book.id).inserted
        }
    }
}
