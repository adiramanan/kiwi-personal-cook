import XCTest
@testable import Kiwi

final class ClientRateLimiterTests: XCTestCase {

    func testInitialRemainingIsFour() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let limiter = ClientRateLimiter(defaults: defaults)

        XCTAssertEqual(limiter.remaining(), 4)
        XCTAssertTrue(limiter.canScan())
    }

    func testRemainingDecrementsAfterRecordingScan() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let limiter = ClientRateLimiter(defaults: defaults)

        limiter.recordScan()
        XCTAssertEqual(limiter.remaining(), 3)

        limiter.recordScan()
        XCTAssertEqual(limiter.remaining(), 2)

        limiter.recordScan()
        XCTAssertEqual(limiter.remaining(), 1)
        XCTAssertTrue(limiter.canScan())

        limiter.recordScan()
        XCTAssertEqual(limiter.remaining(), 0)
        XCTAssertFalse(limiter.canScan())
    }

    func testCanScanReturnsFalseAfterFourScans() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let limiter = ClientRateLimiter(defaults: defaults)

        for _ in 0..<4 {
            limiter.recordScan()
        }

        XCTAssertFalse(limiter.canScan())
        XCTAssertEqual(limiter.remaining(), 0)
    }

    func testRemainingNeverGoesNegative() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let limiter = ClientRateLimiter(defaults: defaults)

        for _ in 0..<10 {
            limiter.recordScan()
        }

        XCTAssertEqual(limiter.remaining(), 0)
        XCTAssertFalse(limiter.canScan())
    }
}
