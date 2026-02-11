import XCTest
@testable import Kiwi

final class ClientRateLimiterTests: XCTestCase {
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "ClientRateLimiterTests")
        userDefaults.removePersistentDomain(forName: "ClientRateLimiterTests")
    }

    func testRemainingDecreasesWithRecordedScans() {
        let fixedNow = Date(timeIntervalSince1970: 1_700_000_000)
        let limiter = ClientRateLimiter(userDefaults: userDefaults, now: { fixedNow })

        XCTAssertEqual(limiter.remaining(), 4)

        limiter.recordScan()
        limiter.recordScan()

        XCTAssertEqual(limiter.remaining(), 2)
        XCTAssertTrue(limiter.canScan())
    }

    func testRemainingResetsOnNextUTCDay() {
        let firstDay = Date(timeIntervalSince1970: 1_700_000_000)
        var now = firstDay

        let limiter = ClientRateLimiter(userDefaults: userDefaults, now: { now })

        for _ in 0..<4 {
            limiter.recordScan()
        }

        XCTAssertEqual(limiter.remaining(), 0)

        now = firstDay.addingTimeInterval(60 * 60 * 24)
        XCTAssertEqual(limiter.remaining(), 4)
    }
}
