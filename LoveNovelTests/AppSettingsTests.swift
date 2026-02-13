import SwiftUI
import XCTest
@testable import LoveNovel

final class AppSettingsTests: XCTestCase {
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
}
