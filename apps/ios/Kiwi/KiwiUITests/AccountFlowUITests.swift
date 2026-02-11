import XCTest

final class AccountFlowUITests: XCTestCase {
    func testAccountTabExists() {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_AUTHENTICATED")
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Account"].waitForExistence(timeout: 3))
    }
}
