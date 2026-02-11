import XCTest

final class ScanFlowUITests: XCTestCase {
    func testScanTabExists() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Scan"].waitForExistence(timeout: 3))
    }
}
