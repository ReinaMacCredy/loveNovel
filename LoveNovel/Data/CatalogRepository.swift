import Foundation
import LoveNovelDomain

public enum CatalogRepositoryError: LocalizedError {
    case missingResource(String)

    public var errorDescription: String? {
        switch self {
        case let .missingResource(name):
            return "Could not find resource \(name).json in bundle."
        }
    }
}

public enum CatalogSource {
    case bundled(fileName: String, bundle: Bundle)
    case rawData(Data)
}

public actor CatalogRepository: CatalogProviding {
    private final class BundleToken {}

    private let source: CatalogSource
    private let decoder: JSONDecoder
    private var cachedFeed: HomeFeed?
    #if DEBUG
    private var loadCount: Int = 0
    #endif

    public init(
        source: CatalogSource = .bundled(fileName: "mock_catalog", bundle: .main),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.source = CatalogRepository.resolveSource(source)
        self.decoder = decoder
    }

    public func fetchHomeFeed() async throws -> HomeFeed {
        if let cachedFeed {
            return cachedFeed
        }

        let data = try loadData()

        if Task.isCancelled {
            throw CancellationError()
        }

        let feed = try decoder.decode(HomeFeed.self, from: data)
        cachedFeed = feed
        return feed
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
                throw CatalogRepositoryError.missingResource(fileName)
            }
            return try Data(contentsOf: url)
        }
    }

    private static func resolveSource(_ source: CatalogSource) -> CatalogSource {
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
}
