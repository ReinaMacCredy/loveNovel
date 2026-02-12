import XCTest

@MainActor
final class TabNavigationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchesOnExploreTab() {
        let app = XCUIApplication()
        app.launch()

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

}
