import Foundation

struct Book: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let author: String
    let summary: String
    let rating: Double
    let accentHex: String
}
