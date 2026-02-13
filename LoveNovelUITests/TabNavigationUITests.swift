import XCTest

@MainActor
final class TabNavigationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchesOnExploreTab() {
        let app = XCUIApplication()
        app.launch()

        activateExploreTab(in: app)
        XCTAssertTrue(app.buttons["All Stories"].waitForExistence(timeout: 4))
    }

    func testTabBarNavigationOrderAndLabels() {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 2))
        XCTAssertEqual(app.tabBars.count, 1)

        let libraryTab = tabBar.buttons["Library"]
        let exploreTab = tabBar.buttons["Explore"]
        let profileTab = tabBar.buttons["Profile"]

        XCTAssertTrue(libraryTab.exists)
        XCTAssertTrue(exploreTab.exists)
        XCTAssertTrue(profileTab.exists)

        libraryTab.tap()
        XCTAssertTrue(app.buttons["History"].waitForExistence(timeout: 2))

        profileTab.tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 2))

        exploreTab.tap()
        XCTAssertTrue(app.buttons["All Stories"].waitForExistence(timeout: 2))
    }

    func testDarkModeSettingSyncsToReaderCenterTapPanel() {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 2))

        tabBar.buttons["Profile"].tap()
        let settingsRow = app.buttons["Settings"]
        XCTAssertTrue(settingsRow.waitForExistence(timeout: 4))
        settingsRow.tap()

        let darkModeRow = app.buttons["Dark mode"]
        XCTAssertTrue(darkModeRow.waitForExistence(timeout: 4))
        darkModeRow.tap()

        let modeOn = app.buttons["On"]
        XCTAssertTrue(modeOn.waitForExistence(timeout: 2))
        modeOn.tap()

        tabBar.buttons["Explore"].tap()
        let riceTeaCover = app.buttons.matching(identifier: "book.cover.rice-tea").firstMatch
        XCTAssertTrue(riceTeaCover.waitForExistence(timeout: 8))
        riceTeaCover.tap()

        let contentTab = app.buttons["novel_detail.tab.content"]
        XCTAssertTrue(contentTab.waitForExistence(timeout: 4))
        contentTab.tap()

        let chapterRow = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "novel_detail.chapter_row.")
        ).firstMatch
        XCTAssertTrue(chapterRow.waitForExistence(timeout: 4))
        chapterRow.tap()

        let tutorialDismiss = app.buttons["reader.tutorial.dismiss"]
        if tutorialDismiss.waitForExistence(timeout: 1.5) {
            tutorialDismiss.tap()
        }

        let readerContent = app.scrollViews["reader.content"]
        XCTAssertTrue(readerContent.waitForExistence(timeout: 4))
        readerContent.tap()

        let settingsTab = app.buttons["reader.panel.tab.settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 4))
        settingsTab.tap()

        let selectedThemeButton = app.buttons["reader.theme.charcoal"]
        XCTAssertTrue(selectedThemeButton.waitForExistence(timeout: 3))
        XCTAssertEqual(selectedThemeButton.value as? String, "selected")
    }

    private func activateExploreTab(in app: XCUIApplication) {
        let exploreTab = app.tabBars.buttons["Explore"]
        if exploreTab.waitForExistence(timeout: 2) {
            exploreTab.tap()
        }
    }
}
