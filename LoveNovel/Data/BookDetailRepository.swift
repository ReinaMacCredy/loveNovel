import Foundation
import LoveNovelDomain

public enum BookDetailRepositoryError: LocalizedError {
    case missingResource(String)

    public var errorDescription: String? {
        switch self {
        case let .missingResource(name):
            return "Could not find resource \(name).json in bundle."
        }
    }
}

public enum BookDetailSource {
    case bundled(fileName: String, bundle: Bundle)
    case rawData(Data)
}

public actor BookDetailRepository: BookDetailProviding {
    private struct BookDetailPayload: Codable, Sendable {
        let details: [BookDetail]
    }

    private final class BundleToken {}

    private let source: BookDetailSource
    private let decoder: JSONDecoder
    private var cachedDetailsByBookId: [String: BookDetail]?
    #if DEBUG
    private var loadCount: Int = 0
    #endif

    public init(
        source: BookDetailSource = .bundled(fileName: "mock_book_details", bundle: .main),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.source = BookDetailRepository.resolveSource(source)
        self.decoder = decoder
    }

    public func fetchDetail(for book: Book) async throws -> BookDetail {
        if let cachedDetail = cachedDetailsByBookId?[book.id] {
            return cachedDetail
        }

        if cachedDetailsByBookId == nil {
            let data = try loadData()

            if Task.isCancelled {
                throw CancellationError()
            }

            let payload = try decoder.decode(BookDetailPayload.self, from: data)
            cachedDetailsByBookId = Dictionary(
                uniqueKeysWithValues: payload.details.map { ($0.bookId, $0) }
            )
        }

        if Task.isCancelled {
            throw CancellationError()
        }

        if let decodedDetail = cachedDetailsByBookId?[book.id] {
            return decodedDetail
        }

        let fallback = Self.fallbackDetail(for: book)
        cachedDetailsByBookId?[book.id] = fallback

        if Task.isCancelled {
            throw CancellationError()
        }

        return fallback
    }

    #if DEBUG
    public func debugLoadCount() -> Int {
        loadCount
    }
    #endif

    private func loadData() throws -> Data {
        #if DEBUG
        loadCount += 1
        #endif

        switch source {
        case let .rawData(data):
            return data
        case let .bundled(fileName, bundle):
            guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
                throw BookDetailRepositoryError.missingResource(fileName)
            }
            return try Data(contentsOf: url)
        }
    }

    private static func resolveSource(_ source: BookDetailSource) -> BookDetailSource {
        switch source {
        case .rawData:
            return source
        case let .bundled(fileName, bundle):
            if bundle.url(forResource: fileName, withExtension: "json") != nil {
                return .bundled(fileName: fileName, bundle: bundle)
            }

            let fallbackBundle = Bundle(for: BundleToken.self)
            return .bundled(fileName: fileName, bundle: fallbackBundle)
        }
    }

    private static func fallbackDetail(for book: Book) -> BookDetail {
        BookDetail(
            bookId: book.id,
            longDescription: book.summary,
            chapterCount: 12,
            viewsLabel: "0",
            status: .ongoing,
            genres: ["Fiction"],
            tags: [book.title.lowercased()],
            uploaderName: "Community",
            sameAuthorBooks: [
                RelatedBook(
                    id: "\(book.id)-same-author",
                    title: book.title,
                    author: book.author,
                    summary: book.summary,
                    rating: book.rating,
                    accentHex: book.accentHex
                )
            ],
            sameUploaderBooks: [
                RelatedBook(
                    id: "\(book.id)-same-uploader",
                    title: book.title,
                    author: book.author,
                    summary: book.summary,
                    rating: book.rating,
                    accentHex: book.accentHex
                )
            ],
            chapterTimestamp: "2020-04-02 00:58",
            reviews: [],
            comments: []
        )
    }
}
