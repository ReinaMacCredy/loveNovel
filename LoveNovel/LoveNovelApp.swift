import SwiftUI

@main
struct LoveNovelApp: App {
    @AppStorage(AppSettingsKey.preferredLanguage) private var preferredLanguageRawValue: String = AppLanguageOption.english.rawValue

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.locale, selectedLanguage.locale)
        }
    }

    private var selectedLanguage: AppLanguageOption {
        AppLanguageOption(rawValue: preferredLanguageRawValue) ?? .english
    }
}
