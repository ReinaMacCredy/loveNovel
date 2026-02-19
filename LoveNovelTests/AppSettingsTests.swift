import SwiftUI
import Testing
@testable import LoveNovel

@Suite("App settings tests", .tags(.settings, .fast), .serialized)
struct AppSettingsTests {
    @Test("Reader dark mode on always uses dark theme")
    func readerDarkModeOptionOnAlwaysUsesDarkTheme() {
        #expect(ReaderDarkModeOption.on.usesDarkTheme(systemScheme: .light))
        #expect(ReaderDarkModeOption.on.usesDarkTheme(systemScheme: .dark))
    }

    @Test("Reader dark mode off always uses light theme")
    func readerDarkModeOptionOffAlwaysUsesLightTheme() {
        #expect(ReaderDarkModeOption.off.usesDarkTheme(systemScheme: .light) == false)
        #expect(ReaderDarkModeOption.off.usesDarkTheme(systemScheme: .dark) == false)
    }

    @Test("Reader dark mode auto follows system scheme")
    func readerDarkModeOptionAutoFollowsSystemScheme() {
        #expect(ReaderDarkModeOption.auto.usesDarkTheme(systemScheme: .light) == false)
        #expect(ReaderDarkModeOption.auto.usesDarkTheme(systemScheme: .dark))
    }

    @Test("App localization uses stored language preference")
    func appLocalizationUsesStoredLanguagePreference() {
        let vietnameseValue = Self.withPreferredLanguage(.vietnamese) {
            AppLocalization.string("Library")
        }
        #expect(vietnameseValue == "Thư viện")

        let englishValue = Self.withPreferredLanguage(.english) {
            AppLocalization.string("Library")
        }
        #expect(englishValue == "Library")
    }

    @Test("App localization format uses localized template")
    func appLocalizationFormatUsesLocalizedTemplate() {
        let formatted = AppLocalization.format(
            "explore.placeholder.book_details",
            language: .vietnamese,
            "Rice Tea"
        )

        #expect(formatted == "Chi tiết Rice Tea sẽ có trong v2.")
    }

    private static func withPreferredLanguage<T>(
        _ language: AppLanguageOption,
        perform: () -> T
    ) -> T {
        let defaults = UserDefaults.standard
        let existingValue = defaults.object(forKey: AppSettingsKey.preferredLanguage)
        defaults.set(language.rawValue, forKey: AppSettingsKey.preferredLanguage)

        defer {
            if let existingValue {
                defaults.set(existingValue, forKey: AppSettingsKey.preferredLanguage)
            } else {
                defaults.removeObject(forKey: AppSettingsKey.preferredLanguage)
            }
        }

        return perform()
    }
}
