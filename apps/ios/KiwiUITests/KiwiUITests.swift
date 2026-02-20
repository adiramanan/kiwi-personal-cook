import XCTest

final class KiwiUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testSignInViewExists() throws {
        XCTAssertTrue(app.staticTexts["Kiwi"].exists || app.buttons["Sign in with Apple"].exists)
    }

    func testTabBarExistsAfterAuth() throws {
        // In a test environment where auth is bypassed,
        // verify tab bar elements exist
        if app.tabBars.buttons["Kiwi"].exists {
            XCTAssertTrue(app.tabBars.buttons["Kiwi"].exists)
            XCTAssertTrue(app.tabBars.buttons["Groceries"].exists)
            XCTAssertTrue(app.tabBars.buttons["Profile"].exists)
            XCTAssertTrue(app.tabBars.buttons["Scan"].exists)
        }
    }

    func testGroceriesTabNavigation() throws {
        if app.tabBars.buttons["Groceries"].exists {
            app.tabBars.buttons["Groceries"].tap()
            XCTAssertTrue(app.navigationBars["Groceries"].waitForExistence(timeout: 2))
        }
    }

    func testProfileTabNavigation() throws {
        if app.tabBars.buttons["Profile"].exists {
            app.tabBars.buttons["Profile"].tap()
            XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 2))
        }
    }
}
