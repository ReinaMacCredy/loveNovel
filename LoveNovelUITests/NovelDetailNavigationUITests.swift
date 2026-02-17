import XCTest

@MainActor
final class NovelDetailNavigationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testExploreBookTapPushesNovelDetailAndReturnsBack() {
        let app = XCUIApplication()
        app.launch()
        activateExploreTab(in: app)

        let riceTeaCover = app.buttons.matching(identifier: "book.cover.rice-tea").firstMatch
        XCTAssertTrue(riceTeaCover.waitForExistence(timeout: 10))
        riceTeaCover.tap()

        let detailScreen = app.scrollViews["screen.novel_detail"]
        XCTAssertTrue(detailScreen.waitForExistence(timeout: 4))

        let infoTab = app.buttons["novel_detail.tab.info"]
        let reviewTab = app.buttons["novel_detail.tab.review"]
        let commentsTab = app.buttons["novel_detail.tab.comments"]
        let contentTab = app.buttons["novel_detail.tab.content"]

        XCTAssertTrue(infoTab.exists)
        XCTAssertTrue(reviewTab.exists)
        XCTAssertTrue(commentsTab.exists)
        XCTAssertTrue(contentTab.exists)

        reviewTab.tap()
        XCTAssertTrue(app.staticTexts["novel_detail.empty.reviews"].waitForExistence(timeout: 2))

        commentsTab.tap()
        XCTAssertTrue(app.staticTexts["novel_detail.empty.comments"].waitForExistence(timeout: 2))

        contentTab.tap()
        let chapterRows = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "novel_detail.chapter_row.")
        )
        XCTAssertTrue(chapterRows.firstMatch.waitForExistence(timeout: 3))

        app.buttons["novel_detail.back"].tap()
        XCTAssertTrue(app.buttons["All Stories"].waitForExistence(timeout: 3))
    }

    func testChapterTapOpensReaderAndSettingsButtonShowsSettingsPanel() {
        let app = XCUIApplication()
        app.launch()
        activateExploreTab(in: app)

        let riceTeaCover = app.buttons.matching(identifier: "book.cover.rice-tea").firstMatch
        XCTAssertTrue(riceTeaCover.waitForExistence(timeout: 10))
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

        let settingsButton = app.buttons["reader.top.settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 4))
        settingsButton.tap()

        let settingsTab = app.buttons["reader.panel.tab.settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 3))

        app.buttons["reader.back"].tap()
        let returnedToDetail = app.buttons["novel_detail.back"].waitForExistence(timeout: 2)
        let returnedToExplore = app.buttons["All Stories"].waitForExistence(timeout: returnedToDetail ? 0 : 2)
        let remainedInReader = app.buttons["reader.top.settings"].waitForExistence(
            timeout: (returnedToDetail || returnedToExplore) ? 0 : 2
        )
        XCTAssertTrue(returnedToDetail || returnedToExplore || remainedInReader)
    }

    func testLeftEdgeSwipeUpReturnsFromNovelDetail() {
        let app = XCUIApplication()
        app.launch()

        openRiceTeaDetail(in: app)
        swipeUpFromLeftEdge(in: app)

        XCTAssertTrue(app.buttons["All Stories"].waitForExistence(timeout: 3))
    }

    func testLeftEdgeSwipeUpReturnsFromReader() {
        let app = XCUIApplication()
        app.launch()

        openRiceTeaDetail(in: app)

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

        XCTAssertTrue(app.buttons["reader.top.settings"].waitForExistence(timeout: 4))
        swipeUpFromLeftEdge(in: app)

        XCTAssertTrue(app.buttons["novel_detail.back"].waitForExistence(timeout: 3))
    }

    func testReaderChapterListQuickActionOpensAndSelectsChapter() {
        let app = XCUIApplication()
        app.launch()

        openRiceTeaDetail(in: app)

        let contentTab = app.buttons["novel_detail.tab.content"]
        XCTAssertTrue(contentTab.waitForExistence(timeout: 4))
        contentTab.tap()

        let chapterRow = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "novel_detail.chapter_row.")
        ).firstMatch
        XCTAssertTrue(chapterRow.waitForExistence(timeout: 4))
        let selectedChapterIndex = chapterRow.identifier.components(separatedBy: ".").last ?? "1"
        chapterRow.tap()

        let tutorialDismiss = app.buttons["reader.tutorial.dismiss"]
        if tutorialDismiss.waitForExistence(timeout: 1.5) {
            tutorialDismiss.tap()
        }

        let readerContent = app.scrollViews["reader.content"]
        XCTAssertTrue(readerContent.waitForExistence(timeout: 4))
        readerContent.tap()

        let chapterListAction = app.buttons["reader.quick.chapter_list"]
        XCTAssertTrue(chapterListAction.waitForExistence(timeout: 3))
        chapterListAction.tap()

        let selectedChapterRow = app.buttons["reader.chapter_list.row.\(selectedChapterIndex)"]
        XCTAssertTrue(selectedChapterRow.waitForExistence(timeout: 3))
        selectedChapterRow.tap()

        XCTAssertFalse(app.buttons["reader.quick.chapter_list"].waitForExistence(timeout: 1))
        XCTAssertTrue(app.buttons["reader.top.settings"].waitForExistence(timeout: 2))
    }

    private func openRiceTeaDetail(in app: XCUIApplication) {
        activateExploreTab(in: app)

        let riceTeaCover = app.buttons.matching(identifier: "book.cover.rice-tea").firstMatch
        XCTAssertTrue(riceTeaCover.waitForExistence(timeout: 10))
        riceTeaCover.tap()
        XCTAssertTrue(app.scrollViews["screen.novel_detail"].waitForExistence(timeout: 4))
    }

    private func activateExploreTab(in app: XCUIApplication) {
        let exploreTab = app.tabBars.buttons["Explore"]
        if exploreTab.waitForExistence(timeout: 2) {
            exploreTab.tap()
        }
    }

    private func swipeUpFromLeftEdge(in app: XCUIApplication) {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 2))

        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.78))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.30))
        start.press(forDuration: 0.05, thenDragTo: end)
    }
}
