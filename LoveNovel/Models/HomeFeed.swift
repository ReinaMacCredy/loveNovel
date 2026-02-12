import Foundation

struct HomeFeed: Codable, Sendable, Equatable {
    let latest: [Book]
    let featured: Book
    let recommended: [Book]
    let moreLikeThis: [Book]
}
