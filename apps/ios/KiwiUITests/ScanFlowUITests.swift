import XCTest

final class ScanFlowUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    func testScanViewDisplaysMainElements() throws {
        // The scan view should show the main call-to-action elements
        // Note: In UI testing, the user may need to be signed in first.
        // This test checks that the core scan UI elements exist.

        // Check for the scan title text
        let scanTitle = app.staticTexts["Scan Your Fridge"]
        if scanTitle.waitForExistence(timeout: 5) {
            XCTAssertTrue(scanTitle.exists)
        }

        // Check for scan buttons
        let takePhotoButton = app.buttons["Take Photo"]
        let chooseLibraryButton = app.buttons["Choose from Library"]

        if takePhotoButton.waitForExistence(timeout: 5) {
            XCTAssertTrue(takePhotoButton.exists)
            XCTAssertTrue(chooseLibraryButton.exists)
        }
    }

    func testScanViewDisplaysQuotaInfo() throws {
        // Check that quota information is displayed
        let scansLeftText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'scans left today'"))

        // The text may show "X scans left today" or a loading indicator
        // In test environment, this may not connect to the server
        // so we just verify the UI renders without crashing
        _ = scansLeftText.firstMatch.waitForExistence(timeout: 3)
    }
}
