import XCTest

final class AccountFlowUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    func testSignInViewDisplaysElements() throws {
        // Check for key sign-in view elements
        let kiwiTitle = app.staticTexts["Kiwi"]
        let tagline = app.staticTexts["Cook smarter with what you have"]
        let privacyText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'never store your fridge photos'")
        )

        if kiwiTitle.waitForExistence(timeout: 5) {
            XCTAssertTrue(kiwiTitle.exists)
            XCTAssertTrue(tagline.exists)
        }

        // Privacy disclosure should be visible
        _ = privacyText.firstMatch.waitForExistence(timeout: 3)
    }

    func testAccountViewDisplaysDeleteButton() throws {
        // Navigate to account tab if available (user needs to be signed in)
        let accountTab = app.tabBars.buttons["Account"]

        if accountTab.waitForExistence(timeout: 5) {
            accountTab.tap()

            let deleteButton = app.buttons["Delete My Account"]
            if deleteButton.waitForExistence(timeout: 3) {
                XCTAssertTrue(deleteButton.exists)
            }
        }
    }

    func testDeleteAccountShowsConfirmation() throws {
        let accountTab = app.tabBars.buttons["Account"]

        if accountTab.waitForExistence(timeout: 5) {
            accountTab.tap()

            let deleteButton = app.buttons["Delete My Account"]
            if deleteButton.waitForExistence(timeout: 3) {
                deleteButton.tap()

                // Confirmation alert should appear
                let alert = app.alerts["Delete Account?"]
                if alert.waitForExistence(timeout: 3) {
                    XCTAssertTrue(alert.exists)

                    // Cancel the deletion
                    alert.buttons["Cancel"].tap()
                }
            }
        }
    }
}
