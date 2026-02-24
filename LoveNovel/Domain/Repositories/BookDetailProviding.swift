import Foundation

public protocol BookDetailProviding: Sendable {
    func fetchDetail(for book: Book) async throws -> BookDetail
}
