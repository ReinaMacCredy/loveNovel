import Foundation

public struct HomeFeed: Codable, Sendable, Equatable {
    public let latest: [Book]
    public let featured: Book
    public let recommended: [Book]
    public let moreLikeThis: [Book]

    public init(latest: [Book], featured: Book, recommended: [Book], moreLikeThis: [Book]) {
        self.latest = latest
        self.featured = featured
        self.recommended = recommended
        self.moreLikeThis = moreLikeThis
    }
}
