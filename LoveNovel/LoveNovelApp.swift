import SwiftUI

@main
struct LoveNovelApp: App {
    @AppStorage(AppSettingsKey.preferredLanguage) private var preferredLanguageRawValue: String = AppLanguageOption.english.rawValue
    @StateObject private var libraryStore = LibraryCollectionStore()

    private let container = AppContainer.live

    init() {
        UITestBootstrap.applyIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(container: container)
                .environmentObject(libraryStore)
                .environment(\.locale, selectedLanguage.locale)
        }
    }

    private var selectedLanguage: AppLanguageOption {
        AppLanguageOption(rawValue: preferredLanguageRawValue) ?? .english
    }
}
