import SwiftUI
import LoveNovelPresentation

@main
struct LoveNovelApp: App {
    private let featureFactory = AppContainer.live

    init() {
        UITestBootstrap.applyIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(featureFactory: featureFactory)
        }
    }
}
