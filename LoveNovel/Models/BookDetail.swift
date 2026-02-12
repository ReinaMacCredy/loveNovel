import Foundation

struct BookDetail: Codable, Sendable, Equatable {
    let bookId: String
    let longDescription: String
    let chapterCount: Int
    let viewsLabel: String
    let status: BookPublicationStatus
    let genres: [String]
    let tags: [String]
    let uploaderName: String
    let sameAuthorBooks: [RelatedBook]
    let sameUploaderBooks: [RelatedBook]
    let chapterTimestamp: String
    let reviews: [BookReview]
    let comments: [BookComment]
}

struct RelatedBook: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let author: String
    let summary: String
    let rating: Double
    let accentHex: String
}

enum BookPublicationStatus: String, Codable, Sendable, Equatable {
    case ongoing
    case completed
}

struct BookChapter: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let index: Int
    let title: String
    let timestampText: String
}

struct BookReview: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let author: String
    let rating: Double
    let body: String
    let createdAtText: String
}

struct BookComment: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let author: String
    let body: String
    let likes: Int
    let createdAtText: String
}
