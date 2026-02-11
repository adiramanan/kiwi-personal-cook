import XCTest

final class AccountFlowUITests: XCTestCase {
    func testAccountTabExists() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Account"].waitForExistence(timeout: 3))
    }
}
