import SwiftUI
import Testing
@testable import LoveNovelCore

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

    @Test("Library sort options support stable and legacy stored values")
    func librarySortOptionsSupportStableAndLegacyStoredValues() {
        #expect(LibraryHistorySortOption.defaultOption.storageValue == "last_read")
        #expect(LibraryBookmarkSortOption.defaultOption.storageValue == "newest_saved")

        #expect(LibraryHistorySortOption.fromStorageValue("last_read") == .lastRead)
        #expect(LibraryHistorySortOption.fromStorageValue("Mới đọc") == .lastRead)
        #expect(LibraryBookmarkSortOption.fromStorageValue("newest_saved") == .newestSaved)
        #expect(LibraryBookmarkSortOption.fromStorageValue("Mới lưu") == .newestSaved)
        #expect(LibraryHistorySortOption.fromStorageValue("unknown") == nil)
        #expect(LibraryBookmarkSortOption.fromStorageValue("unknown") == nil)
    }

    @Test("Library sort localization keys resolve in both languages")
    func librarySortLocalizationKeysResolveInBothLanguages() {
        #expect(
            AppLocalization.string(LibraryHistorySortOption.lastRead.localizationKey, language: .english)
                == "Recently read"
        )
        #expect(
            AppLocalization.string(LibraryHistorySortOption.lastRead.localizationKey, language: .vietnamese)
                == "Mới đọc"
        )
        #expect(AppLocalization.string("library.sort.action.reset", language: .english) == "Reset to default")
        #expect(AppLocalization.string("library.sort.action.reset", language: .vietnamese) == "Đặt lại mặc định")
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
