import XCTest

final class KitchenFlowTests: XCTestCase {
    private func launch(extra: [String] = []) -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--kitchen-ui-tests"] + extra
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Cook"].waitForExistence(timeout: 10))
        return app
    }
    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    func testFamilyGoalsAndIngredientManagement() {
        let app = launch()
        app.tabBars.buttons["Family"].tap()
        XCTAssertTrue(app.staticTexts["Maya"].waitForExistence(timeout: 3))
        capture(app, name: "Family profiles")
        app.buttons["Add family member"].tap()
        let name = app.textFields["Name"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        name.tap(); name.typeText("Sam")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Sam"].waitForExistence(timeout: 4))
        app.tabBars.buttons["Fridge"].tap()
        app.buttons["Add ingredient manually"].tap()
        let ingredient = app.textFields["Ingredient name"]
        XCTAssertTrue(ingredient.waitForExistence(timeout: 3))
        ingredient.tap(); ingredient.typeText("tomato")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.buttons["Edit tomato"].waitForExistence(timeout: 4))
        capture(app, name: "Saved fridge inventory")
    }
    func testRecipesAndShoppingList() {
        let app = launch()
        app.buttons["Find recipes"].tap()
        let recipe = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Lemony spinach rice")).firstMatch
        app.swipeUp()
        XCTAssertTrue(recipe.waitForExistence(timeout: 5))
        capture(app, name: "Cook now and shopping suggestions")
        recipe.tap()
        XCTAssertTrue(app.staticTexts["For everyone at the table"].waitForExistence(timeout: 4))
        capture(app, name: "Personal portions and nutrition")
        for _ in 0..<4 {
            if app.buttons["Add missing items to shopping list"].isHittable { break }
            app.swipeUp()
        }
        app.buttons["Add missing items to shopping list"].tap()
        XCTAssertTrue(app.buttons["Added to shopping list"].exists)
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["Shopping list"].tap()
        XCTAssertTrue(app.staticTexts["lemon"].waitForExistence(timeout: 3))
        capture(app, name: "Shopping checklist")
    }
    func testPhotoReviewSavesIngredientsWithoutGeneratingRecipes() {
        let app = launch()
        app.buttons["Scan your fridge"].tap()
        XCTAssertTrue(app.buttons["Load test photo"].waitForExistence(timeout: 3))
        app.buttons["Load test photo"].tap()
        app.buttons["Identify ingredients"].tap()
        XCTAssertTrue(app.buttons["Save to my fridge"].waitForExistence(timeout: 8))
        capture(app, name: "Editable photo recognition")
        app.buttons["Save to my fridge"].tap()
        app.tabBars.buttons["Fridge"].tap()
        XCTAssertTrue(app.buttons["Edit tomato"].waitForExistence(timeout: 4))
        app.tabBars.buttons["Cook"].tap()
        XCTAssertFalse(app.staticTexts["Spinach & egg rice"].exists)
    }

    func testGenerationNetworkError() {
        let app = launch(extra: ["--generation-fails"])
        app.buttons["Find recipes"].tap()
        XCTAssertTrue(app.alerts["Couldn't finish"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.alerts.staticTexts["No internet connection. Check your network and try again."].exists)
    }
    func testExpiredSessionReturnsToSignIn() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--kitchen-ui-tests", "--session-expired"]
        app.launch()
        XCTAssertTrue(app.buttons["Sign in with Apple"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Your session has expired. Please sign in again."].exists)
        XCTAssertFalse(app.alerts["Couldn't finish"].exists)
        XCTAssertFalse(app.tabBars.buttons["Cook"].exists)
    }
    func testGenerationQuotaError() {
        let app = launch(extra: ["--generation-limited"])
        app.buttons["Find recipes"].tap()
        XCTAssertTrue(app.alerts["Couldn't finish"].waitForExistence(timeout: 5))
        capture(app, name: "Daily allowance error")
    }
    func testLargeTypeDarkMode() {
        let app = launch(extra: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL", "--dark-mode"])
        XCTAssertTrue(app.buttons["Find recipes"].exists)
        capture(app, name: "Cook with large text and dark appearance")
        for _ in 0..<5 {
            if app.buttons["Find recipes"].isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(app.buttons["Find recipes"].isHittable)
        capture(app, name: "Accessible cooking action in dark appearance")
        app.tabBars.buttons["Family"].tap()
        XCTAssertTrue(app.staticTexts["Maya"].waitForExistence(timeout: 3))
        capture(app, name: "Family with large text and dark appearance")
    }
}
