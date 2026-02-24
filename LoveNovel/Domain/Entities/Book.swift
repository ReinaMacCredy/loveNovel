import Foundation

public struct Book: Codable, Identifiable, Sendable, Equatable, Hashable {
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
