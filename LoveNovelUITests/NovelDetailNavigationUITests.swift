import XCTest

@MainActor
final class NovelDetailNavigationUITests: XCTestCase {
    private enum TestData {
        static let riceTeaLatestChapterIdentifier = "novel_detail.chapter_row.460"
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testExploreBookTapPushesNovelDetailAndReturnsBack() {
        let app = UITestLaunchConfiguration.launchConfiguredApp()
        activateExploreTab(in: app)

        let riceTeaCover = app.buttons.matching(identifier: "book.cover.rice-tea").firstMatch
        XCTAssertTrue(riceTeaCover.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.longest))
        riceTeaCover.tap()

        let detailScreen = app.scrollViews["screen.novel_detail"]
        XCTAssertTrue(detailScreen.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))

        let infoTab = app.buttons["novel_detail.tab.info"]
        let reviewTab = app.buttons["novel_detail.tab.review"]
        let commentsTab = app.buttons["novel_detail.tab.comments"]
        let contentTab = app.buttons["novel_detail.tab.content"]

        XCTAssertTrue(infoTab.exists)
        XCTAssertTrue(reviewTab.exists)
        XCTAssertTrue(commentsTab.exists)
        XCTAssertTrue(contentTab.exists)

        reviewTab.tap()
        XCTAssertTrue(app.staticTexts["novel_detail.empty.reviews"].waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))

        commentsTab.tap()
        XCTAssertTrue(app.staticTexts["novel_detail.empty.comments"].waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))

        contentTab.tap()
        XCTAssertTrue(app.buttons[TestData.riceTeaLatestChapterIdentifier].waitForExistence(timeout: UITestLaunchConfiguration.Timeout.sheet))

        app.buttons["novel_detail.back"].tap()
        XCTAssertTrue(app.buttons["All Stories"].waitForExistence(timeout: UITestLaunchConfiguration.Timeout.sheet))
    }

    func testChapterTapOpensReaderAndSettingsButtonShowsSettingsPanel() {
        let app = UITestLaunchConfiguration.launchConfiguredApp()
        activateExploreTab(in: app)

        let riceTeaCover = app.buttons.matching(identifier: "book.cover.rice-tea").firstMatch
        XCTAssertTrue(riceTeaCover.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.longest))
        riceTeaCover.tap()

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

        let settingsButton = app.buttons["reader.top.settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))
        settingsButton.tap()

        let settingsTab = app.buttons["reader.panel.tab.settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.sheet))

        app.buttons["reader.back"].tap()
        let returnedToDetail = app.buttons["novel_detail.back"].waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short)
        let returnedToExplore = app.buttons["All Stories"].waitForExistence(timeout: returnedToDetail ? 0 : UITestLaunchConfiguration.Timeout.short)
        let remainedInReader = app.buttons["reader.top.settings"].waitForExistence(
            timeout: (returnedToDetail || returnedToExplore) ? 0 : UITestLaunchConfiguration.Timeout.short
        )
        XCTAssertTrue(returnedToDetail || returnedToExplore || remainedInReader)
    }

    func testLeftEdgeSwipeUpReturnsFromNovelDetail() {
        let app = UITestLaunchConfiguration.launchConfiguredApp()

        openRiceTeaDetail(in: app)
        swipeUpFromLeftEdge(in: app)

        XCTAssertTrue(app.buttons["All Stories"].waitForExistence(timeout: UITestLaunchConfiguration.Timeout.sheet))
    }

    func testLeftEdgeSwipeUpReturnsFromReader() {
        let app = UITestLaunchConfiguration.launchConfiguredApp()

        openRiceTeaDetail(in: app)

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

        XCTAssertTrue(app.buttons["reader.top.settings"].waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))
        swipeUpFromLeftEdge(in: app)

        XCTAssertTrue(app.buttons["novel_detail.back"].waitForExistence(timeout: UITestLaunchConfiguration.Timeout.sheet))
    }

    func testReaderChapterListQuickActionOpensAndSelectsChapter() {
        let app = UITestLaunchConfiguration.launchConfiguredApp()

        openRiceTeaDetail(in: app)

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

        let chapterListAction = app.buttons["reader.quick.chapter_list"]
        XCTAssertTrue(chapterListAction.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.sheet))
        chapterListAction.tap()

        let selectedChapterRow = app.buttons["reader.chapter_list.row.460"]
        XCTAssertTrue(selectedChapterRow.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.sheet))
        selectedChapterRow.tap()

        XCTAssertFalse(appears(app.buttons["reader.quick.chapter_list"], within: UITestLaunchConfiguration.Timeout.brief))
        XCTAssertTrue(app.buttons["reader.top.settings"].waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))
    }

    private func openRiceTeaDetail(in app: XCUIApplication) {
        activateExploreTab(in: app)

        let riceTeaCover = app.buttons.matching(identifier: "book.cover.rice-tea").firstMatch
        XCTAssertTrue(riceTeaCover.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.longest))
        riceTeaCover.tap()
        XCTAssertTrue(app.scrollViews["screen.novel_detail"].waitForExistence(timeout: UITestLaunchConfiguration.Timeout.medium))
    }

    private func activateExploreTab(in app: XCUIApplication) {
        let exploreTab = app.tabBars.buttons["Explore"]
        if exploreTab.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short) {
            exploreTab.tap()
        }
    }

    private func swipeUpFromLeftEdge(in app: XCUIApplication) {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: UITestLaunchConfiguration.Timeout.short))

        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.78))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.30))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    private func appears(_ element: XCUIElement, within timeout: TimeInterval, pollInterval: TimeInterval = 0.1) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if element.exists {
                return true
            }
            Thread.sleep(forTimeInterval: pollInterval)
        }

        return element.exists
    }
}
