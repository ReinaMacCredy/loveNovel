import XCTest

@MainActor
final class TabNavigationUITests: XCTestCase {
    private enum TestData {
        static let riceTeaLatestChapterIdentifier = "novel_detail.chapter_row.460"
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchesOnExploreTab() {
        let app = UITestLaunchConfiguration.launchConfiguredApp()

        activateExploreTab(in: app)
        XCTAssertTrue(app.buttons["All Stories"].waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))
    }

    func testTabBarNavigationOrderAndLabels() {
        let app = UITestLaunchConfiguration.launchConfiguredApp()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))
        XCTAssertEqual(app.tabBars.count, 1)

        let libraryTab = tabBar.buttons["Library"]
        let exploreTab = tabBar.buttons["Explore"]
        let profileTab = tabBar.buttons["Profile"]

        XCTAssertTrue(libraryTab.exists)
        XCTAssertTrue(exploreTab.exists)
        XCTAssertTrue(profileTab.exists)

        libraryTab.tap()
        XCTAssertTrue(app.buttons["History"].waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))

        profileTab.tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))

        exploreTab.tap()
        XCTAssertTrue(app.buttons["All Stories"].waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))
    }

    func testAllStoriesButtonShowsStoryModeSheetAndAppliesSelection() {
        let app = UITestLaunchConfiguration.launchConfiguredApp()

        activateExploreTab(in: app)

        let storyModeButtonByIdentifier = app.buttons["explore.header.story_mode"]
        let storyModeButtonByEnglishLabel = app.buttons["All Stories"]
        let storyModeButtonByVietnameseLabel = app.buttons["Tất cả"]
        let storyModeButton = storyModeButtonByIdentifier.exists
            ? storyModeButtonByIdentifier
            : (storyModeButtonByEnglishLabel.exists ? storyModeButtonByEnglishLabel : storyModeButtonByVietnameseLabel)
        XCTAssertTrue(storyModeButton.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))
        storyModeButton.tap()

        let femaleOption = app.buttons.matching(
            NSPredicate(format: "label IN %@", ["Female Stories", "Truyện Nữ"])
        ).firstMatch
        XCTAssertTrue(femaleOption.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.sheet))
        femaleOption.tap()

        let submitButton = app.buttons.matching(
            NSPredicate(format: "label IN %@", ["Submit", "Gửi"])
        ).firstMatch
        XCTAssertTrue(submitButton.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))
        submitButton.tap()

        let submitButtonAfterDismiss = app.buttons.matching(
            NSPredicate(format: "label IN %@", ["Submit", "Gửi"])
        ).firstMatch
        XCTAssertFalse(submitButtonAfterDismiss.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.brief))

        let updatedStoryModeButton = app.buttons["explore.header.story_mode"].exists
            ? app.buttons["explore.header.story_mode"]
            : app.buttons["All Stories"]
        XCTAssertTrue(updatedStoryModeButton.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))
        XCTAssertFalse(updatedStoryModeButton.label.isEmpty)
    }

    func testLibrarySortSettingsScreenOpensFromGearButton() {
        let app = UITestLaunchConfiguration.launchConfiguredApp()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))

        tabBar.buttons["Library"].tap()

        let sortSettingsButton = app.buttons["Library sort settings"]
        XCTAssertTrue(sortSettingsButton.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))
        sortSettingsButton.tap()

        let recentReadOption = app.buttons.matching(
            NSPredicate(format: "label IN %@", ["Recently read", "Mới đọc"])
        ).firstMatch
        XCTAssertTrue(recentReadOption.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))

        let recentSavedOption = app.buttons.matching(
            NSPredicate(format: "label IN %@", ["Recently saved", "Mới lưu"])
        ).firstMatch
        XCTAssertTrue(recentSavedOption.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))

        let backButton = app.buttons["Library sort back"]
        XCTAssertTrue(backButton.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))

        backButton.tap()

        let historyButton = app.buttons.matching(
            NSPredicate(format: "label IN %@", ["History", "Lịch sử"])
        ).firstMatch
        XCTAssertTrue(historyButton.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))
    }

    func testLibraryRowTapNavigatesToNovelDetail() {
        let app = UITestLaunchConfiguration.launchConfiguredApp(seedLibrary: true)

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))
        tabBar.buttons["Library"].tap()

        let seededRow = app.descendants(matching: .any)
            .matching(identifier: "library.row.ui-seed-book")
            .firstMatch
        XCTAssertTrue(seededRow.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))
        seededRow.tap()

        let detailScreen = app.scrollViews["screen.novel_detail"]
        XCTAssertTrue(detailScreen.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))
    }

    func testLibraryHeaderSearchFiltersSeededEntriesLocally() {
        let app = UITestLaunchConfiguration.launchConfiguredApp(seedLibrary: true)

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))
        tabBar.buttons["Library"].tap()

        let searchButton = app.buttons["library.header.search"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))
        searchButton.tap()

        let searchInput = app.textFields["library.search.input"]
        XCTAssertTrue(searchInput.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))
        searchInput.tap()
        searchInput.typeText("Seeded")

        let seededRow = app.descendants(matching: .any)
            .matching(identifier: "library.row.ui-seed-book")
            .firstMatch
        XCTAssertTrue(seededRow.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))

        let clearButton = app.buttons["library.search.clear"]
        if clearButton.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.brief) {
            clearButton.tap()
        }
        searchInput.typeText("No Match")

        let noResultsTitle = app.staticTexts["library.search.no_results.title"]
        XCTAssertTrue(noResultsTitle.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))
    }

    func testLibraryMenuDownloadIsDisabledWithReason() {
        let app = UITestLaunchConfiguration.launchConfiguredApp(seedLibrary: true)

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))
        tabBar.buttons["Library"].tap()

        let rowMenuButton = app.descendants(matching: .any)
            .matching(identifier: "library.row.menu.ui-seed-book")
            .firstMatch
        XCTAssertTrue(rowMenuButton.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))
        rowMenuButton.tap()

        let disabledReason = app.descendants(matching: .any)
            .matching(identifier: "library.menu.download.unavailable_reason")
            .firstMatch
        XCTAssertTrue(disabledReason.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))
    }

    func testExploreFilterButtonOpensAllStoriesListAndNavigatesToDetail() {
        let app = UITestLaunchConfiguration.launchConfiguredApp()

        activateExploreTab(in: app)

        let filterButton = app.buttons["explore.header.filter"]
        XCTAssertTrue(filterButton.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))
        filterButton.tap()

        let firstRow = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "explore.all_stories.row.")
        ).firstMatch
        XCTAssertTrue(firstRow.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.list))
        firstRow.tap()

        XCTAssertTrue(app.scrollViews["screen.novel_detail"].waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))
    }

    func testDarkModeSettingSyncsToReaderCenterTapPanel() {
        let app = UITestLaunchConfiguration.launchConfiguredApp()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))

        tabBar.buttons["Profile"].tap()
        let settingsRow = app.buttons["profile.row.settings"].exists
            ? app.buttons["profile.row.settings"]
            : app.buttons.matching(
                NSPredicate(format: "label IN %@", ["Settings", "Cài đặt"])
            ).firstMatch
        XCTAssertTrue(settingsRow.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))
        settingsRow.tap()

        let darkModeRow = app.buttons["settings.row.dark_mode"].exists
            ? app.buttons["settings.row.dark_mode"]
            : app.buttons.matching(
                NSPredicate(format: "label IN %@", ["Dark mode", "Chế độ tối"])
            ).firstMatch
        XCTAssertTrue(darkModeRow.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))
        darkModeRow.tap()

        let modeOn = app.buttons["settings.dark_mode.mode.on"].exists
            ? app.buttons["settings.dark_mode.mode.on"]
            : app.buttons.matching(
                NSPredicate(format: "label IN %@", ["On", "Bật"])
            ).firstMatch
        XCTAssertTrue(modeOn.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))
        modeOn.tap()
        let darkThemeCharcoal = app.buttons["settings.dark_mode.dark_theme.charcoal"]
        if appears(darkThemeCharcoal, within: UITestLaunchConfiguration.Timeout.brief) {
            darkThemeCharcoal.tap()
        }

        tabBar.buttons["Explore"].tap()
        let riceTeaCover = app.buttons.matching(identifier: "book.cover.rice-tea").firstMatch
        XCTAssertTrue(riceTeaCover.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.long))
        riceTeaCover.tap()
        waitForDetailLoadingToFinish(in: app)

        let contentTab = app.buttons["novel_detail.tab.content"]
        XCTAssertTrue(contentTab.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))
        contentTab.tap()

        let chapterRow = app.buttons[TestData.riceTeaLatestChapterIdentifier]
        XCTAssertTrue(chapterRow.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))
        chapterRow.tap()

        let tutorialDismiss = app.buttons["reader.tutorial.dismiss"]
        if appears(tutorialDismiss, within: UITestLaunchConfiguration.Timeout.tutorial) {
            tutorialDismiss.tap()
        }

        let readerContent = app.scrollViews["reader.content"]
        XCTAssertTrue(readerContent.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))
        readerContent.tap()

        let settingsTab = app.buttons["reader.panel.tab.settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))
        settingsTab.tap()

        let lightThemeButton = app.buttons["reader.theme.light"]
        XCTAssertTrue(lightThemeButton.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.sheet))

        let selectedThemes = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@ AND value IN %@",
                "reader.theme.",
                ["selected", "đã chọn"]
            )
        )
        XCTAssertGreaterThan(selectedThemes.count, 0)
    }

    private func activateExploreTab(in app: XCUIApplication) {
        let exploreTab = app.tabBars.buttons["Explore"]
        if exploreTab.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short) {
            exploreTab.tap()
        }
    }

    private func appears(_ element: XCUIElement, within timeout: TimeInterval) -> Bool {
        element.waitForExistence(timeout: timeout)
    }

    private func waitForDetailLoadingToFinish(in app: XCUIApplication) {
        let loadingView = app.otherElements["novel_detail.loading"]
        guard loadingView.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.brief) else {
            return
        }

        XCTAssertTrue(waitForDisappearance(of: loadingView, within: UITestLaunchConfiguration.Timeout.long))
    }

    private func waitForDisappearance(of element: XCUIElement, within timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
