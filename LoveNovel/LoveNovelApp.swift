import SwiftUI
import LoveNovelPresentation

@main
struct LoveNovelApp: App {
    init() {
        UITestBootstrap.applyIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
    }
}
