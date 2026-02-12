import Foundation

protocol CatalogProviding: Sendable {
    func fetchHomeFeed() async throws -> HomeFeed
}
