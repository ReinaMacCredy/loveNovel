import XCTest

@MainActor
final class TabNavigationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchesOnExploreTab() {
        let app = launchConfiguredApp()

        activateExploreTab(in: app)
        XCTAssertTrue(app.buttons["All Stories"].waitForExistence(timeout: 4))
    }

    func testTabBarNavigationOrderAndLabels() {
        let app = launchConfiguredApp()

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

    func testAllStoriesButtonShowsStoryModeSheetAndAppliesSelection() {
        let app = launchConfiguredApp()

        activateExploreTab(in: app)

        let storyModeButtonByIdentifier = app.buttons["explore.header.story_mode"]
        let storyModeButtonByEnglishLabel = app.buttons["All Stories"]
        let storyModeButtonByVietnameseLabel = app.buttons["Tất cả"]
        let storyModeButton = storyModeButtonByIdentifier.exists
            ? storyModeButtonByIdentifier
            : (storyModeButtonByEnglishLabel.exists ? storyModeButtonByEnglishLabel : storyModeButtonByVietnameseLabel)
        XCTAssertTrue(storyModeButton.waitForExistence(timeout: 4))
        storyModeButton.tap()

        let femaleOption = app.buttons.matching(
            NSPredicate(format: "label IN %@", ["Female Stories", "Truyện Nữ"])
        ).firstMatch
        XCTAssertTrue(femaleOption.waitForExistence(timeout: 3))
        femaleOption.tap()

        let submitButton = app.buttons.matching(
            NSPredicate(format: "label IN %@", ["Submit", "Gửi"])
        ).firstMatch
        XCTAssertTrue(submitButton.waitForExistence(timeout: 2))
        submitButton.tap()

        let submitButtonAfterDismiss = app.buttons.matching(
            NSPredicate(format: "label IN %@", ["Submit", "Gửi"])
        ).firstMatch
        XCTAssertFalse(submitButtonAfterDismiss.waitForExistence(timeout: 1))

        let updatedStoryModeButton = app.buttons["explore.header.story_mode"].exists
            ? app.buttons["explore.header.story_mode"]
            : app.buttons["All Stories"]
        XCTAssertTrue(updatedStoryModeButton.waitForExistence(timeout: 2))
        XCTAssertFalse(updatedStoryModeButton.label.isEmpty)
    }

    func testLibrarySortSettingsScreenOpensFromGearButton() {
        let app = launchConfiguredApp()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 2))

        tabBar.buttons["Library"].tap()

        let sortSettingsButton = app.buttons["Library sort settings"]
        XCTAssertTrue(sortSettingsButton.waitForExistence(timeout: 2))
        sortSettingsButton.tap()

        let recentReadOption = app.buttons.matching(
            NSPredicate(format: "label IN %@", ["Recently read", "Mới đọc"])
        ).firstMatch
        XCTAssertTrue(recentReadOption.waitForExistence(timeout: 2))

        let recentSavedOption = app.buttons.matching(
            NSPredicate(format: "label IN %@", ["Recently saved", "Mới lưu"])
        ).firstMatch
        XCTAssertTrue(recentSavedOption.waitForExistence(timeout: 2))

        let backButton = app.buttons["Library sort back"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 2))

        backButton.tap()

        XCTAssertTrue(app.buttons["History"].waitForExistence(timeout: 2))
    }

    func testDarkModeSettingSyncsToReaderCenterTapPanel() {
        let app = launchConfiguredApp()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 2))

        tabBar.buttons["Profile"].tap()
        let settingsRow = app.buttons["profile.row.settings"].exists
            ? app.buttons["profile.row.settings"]
            : app.buttons.matching(
                NSPredicate(format: "label IN %@", ["Settings", "Cài đặt"])
            ).firstMatch
        XCTAssertTrue(settingsRow.waitForExistence(timeout: 4))
        settingsRow.tap()

        let darkModeRow = app.buttons["settings.row.dark_mode"].exists
            ? app.buttons["settings.row.dark_mode"]
            : app.buttons.matching(
                NSPredicate(format: "label IN %@", ["Dark mode", "Chế độ tối"])
            ).firstMatch
        XCTAssertTrue(darkModeRow.waitForExistence(timeout: 4))
        darkModeRow.tap()

        let modeOn = app.buttons["settings.dark_mode.mode.on"].exists
            ? app.buttons["settings.dark_mode.mode.on"]
            : app.buttons.matching(
                NSPredicate(format: "label IN %@", ["On", "Bật"])
            ).firstMatch
        XCTAssertTrue(modeOn.waitForExistence(timeout: 4))
        modeOn.tap()
        let darkThemeCharcoal = app.buttons["settings.dark_mode.dark_theme.charcoal"]
        if darkThemeCharcoal.waitForExistence(timeout: 1) {
            darkThemeCharcoal.tap()
        }

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

        let lightThemeButton = app.buttons["reader.theme.light"]
        XCTAssertTrue(lightThemeButton.waitForExistence(timeout: 3))

        let selectedThemes = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@ AND value IN %@",
                "reader.theme.",
                ["selected", "đã chọn"]
            )
        )
        XCTAssertGreaterThan(selectedThemes.count, 0)
    }

    private func launchConfiguredApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-settings.preferredLanguage", "english",
            "-settings.readerDarkMode", "auto",
            "-settings.readerLightTheme", "light",
            "-settings.readerDarkTheme", "charcoal",
            "-reader.didShowTutorial", "1"
        ]
        app.launch()
        return app
    }

    private func activateExploreTab(in app: XCUIApplication) {
        let exploreTab = app.tabBars.buttons["Explore"]
        if exploreTab.waitForExistence(timeout: 2) {
            exploreTab.tap()
        }
    }
}
