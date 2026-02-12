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

        let tabBar = app.otherElements["bottom-tab-bar"]
        XCTAssertTrue(tabBar.waitForExistence(timeout: 2))
        XCTAssertEqual(app.otherElements.matching(identifier: "bottom-tab-bar").count, 1)
        XCTAssertEqual(app.tabBars.count, 0)

        let libraryTab = tabBar.descendants(matching: .button)["tab-library"]
        let exploreTab = tabBar.descendants(matching: .button)["tab-explore"]
        let profileTab = tabBar.descendants(matching: .button)["tab-profile"]

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
