import XCTest
import UIKit
@testable import Kiwi

@MainActor
final class ScanViewModelTests: XCTestCase {
    func testLoadQuotaSuccess() async {
        let useCase = GetQuotaUseCase(executeImpl: {
            QuotaInfo(remaining: 3, limit: 4, resetsAt: Date())
        })
        let viewModel = ScanViewModel(getQuotaUseCase: useCase)

        await viewModel.loadQuota()

        XCTAssertEqual(viewModel.quota?.remaining, 3)
        XCTAssertNil(viewModel.error)
    }

    func testLoadQuotaFailureSetsError() async {
        enum TestError: Error { case failed }

        let useCase = GetQuotaUseCase(executeImpl: {
            throw TestError.failed
        })
        let viewModel = ScanViewModel(getQuotaUseCase: useCase)

        await viewModel.loadQuota()

        XCTAssertEqual(viewModel.error, .network)
    }

    func testSelectImageRecordsLocalScan() {
        let defaults = UserDefaults(suiteName: "ScanViewModelTests")!
        defaults.removePersistentDomain(forName: "ScanViewModelTests")

        let limiter = ClientRateLimiter(userDefaults: defaults, now: { Date(timeIntervalSince1970: 1_700_000_000) })
        let viewModel = ScanViewModel(getQuotaUseCase: GetQuotaUseCase(executeImpl: {
            QuotaInfo(remaining: 4, limit: 4, resetsAt: Date())
        }), rateLimiter: limiter)

        let before = viewModel.localRemaining
        viewModel.selectImage(UIImage(systemName: "leaf")!)
        let after = viewModel.localRemaining

        XCTAssertEqual(before - after, 1)
    }
}
