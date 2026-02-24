import Foundation

public struct BookDetail: Codable, Sendable, Equatable {
    public let bookId: String
    public let longDescription: String
    public let chapterCount: Int
    public let viewsLabel: String
    public let status: BookPublicationStatus
    public let genres: [String]
    public let tags: [String]
    public let uploaderName: String
    public let sameAuthorBooks: [RelatedBook]
    public let sameUploaderBooks: [RelatedBook]
    public let chapterTimestamp: String
    public let reviews: [BookReview]
    public let comments: [BookComment]

    public init(
        bookId: String,
        longDescription: String,
        chapterCount: Int,
        viewsLabel: String,
        status: BookPublicationStatus,
        genres: [String],
        tags: [String],
        uploaderName: String,
        sameAuthorBooks: [RelatedBook],
        sameUploaderBooks: [RelatedBook],
        chapterTimestamp: String,
        reviews: [BookReview],
        comments: [BookComment]
    ) {
        self.bookId = bookId
        self.longDescription = longDescription
        self.chapterCount = chapterCount
        self.viewsLabel = viewsLabel
        self.status = status
        self.genres = genres
        self.tags = tags
        self.uploaderName = uploaderName
        self.sameAuthorBooks = sameAuthorBooks
        self.sameUploaderBooks = sameUploaderBooks
        self.chapterTimestamp = chapterTimestamp
        self.reviews = reviews
        self.comments = comments
    }
}

public struct RelatedBook: Codable, Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let author: String
    public let summary: String
    public let rating: Double
    public let accentHex: String

    public init(
        id: String,
        title: String,
        author: String,
        summary: String,
        rating: Double,
        accentHex: String
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.summary = summary
        self.rating = rating
        self.accentHex = accentHex
    }
}

public enum BookPublicationStatus: String, Codable, Sendable, Equatable {
    case ongoing
    case completed
}

public struct BookChapter: Codable, Identifiable, Sendable, Equatable {
    public let id: String
    public let index: Int
    public let title: String
    public let timestampText: String

    public init(id: String, index: Int, title: String, timestampText: String) {
        self.id = id
        self.index = index
        self.title = title
        self.timestampText = timestampText
    }
}

public struct BookReview: Codable, Identifiable, Sendable, Equatable {
    public let id: String
    public let author: String
    public let rating: Double
    public let body: String
    public let createdAtText: String

    public init(id: String, author: String, rating: Double, body: String, createdAtText: String) {
        self.id = id
        self.author = author
        self.rating = rating
        self.body = body
        self.createdAtText = createdAtText
    }
}

public struct BookComment: Codable, Identifiable, Sendable, Equatable {
    public let id: String
    public let author: String
    public let body: String
    public let likes: Int
    public let createdAtText: String

    public init(id: String, author: String, body: String, likes: Int, createdAtText: String) {
        self.id = id
        self.author = author
        self.body = body
        self.likes = likes
        self.createdAtText = createdAtText
    }
}
