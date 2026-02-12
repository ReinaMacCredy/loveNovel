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

        XCTAssertTrue(app.buttons["Library"].exists)
        XCTAssertTrue(app.buttons["Explore"].exists)
        XCTAssertTrue(app.buttons["Profile"].exists)

        app.buttons["Library"].tap()
        XCTAssertTrue(app.buttons["History"].waitForExistence(timeout: 2))

        app.buttons["Profile"].tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 2))

        app.buttons["Explore"].tap()
        XCTAssertTrue(app.buttons["All Stories"].waitForExistence(timeout: 2))
    }
}
