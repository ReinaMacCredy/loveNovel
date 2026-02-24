import Foundation

public protocol CatalogProviding: Sendable {
    func fetchHomeFeed() async throws -> HomeFeed
}
