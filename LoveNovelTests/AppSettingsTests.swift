import SwiftUI
import XCTest
@testable import LoveNovel

final class AppSettingsTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.set(AppLanguageOption.english.rawValue, forKey: AppSettingsKey.preferredLanguage)
    }

    func testReaderDarkModeOptionOnAlwaysUsesDarkTheme() {
        XCTAssertTrue(ReaderDarkModeOption.on.usesDarkTheme(systemScheme: .light))
        XCTAssertTrue(ReaderDarkModeOption.on.usesDarkTheme(systemScheme: .dark))
    }

    func testReaderDarkModeOptionOffAlwaysUsesLightTheme() {
        XCTAssertFalse(ReaderDarkModeOption.off.usesDarkTheme(systemScheme: .light))
        XCTAssertFalse(ReaderDarkModeOption.off.usesDarkTheme(systemScheme: .dark))
    }

    func testReaderDarkModeOptionAutoFollowsSystemScheme() {
        XCTAssertFalse(ReaderDarkModeOption.auto.usesDarkTheme(systemScheme: .light))
        XCTAssertTrue(ReaderDarkModeOption.auto.usesDarkTheme(systemScheme: .dark))
    }

    func testAppLocalizationUsesStoredLanguagePreference() {
        UserDefaults.standard.set(AppLanguageOption.vietnamese.rawValue, forKey: AppSettingsKey.preferredLanguage)
        XCTAssertEqual(AppLocalization.string("Library"), "Thư viện")

        UserDefaults.standard.set(AppLanguageOption.english.rawValue, forKey: AppSettingsKey.preferredLanguage)
        XCTAssertEqual(AppLocalization.string("Library"), "Library")
    }

    func testAppLocalizationFormatUsesLocalizedTemplate() {
        UserDefaults.standard.set(AppLanguageOption.vietnamese.rawValue, forKey: AppSettingsKey.preferredLanguage)
        XCTAssertEqual(
            AppLocalization.format("explore.placeholder.book_details", "Rice Tea"),
            "Chi tiết Rice Tea sẽ có trong v2."
        )
    }
}
