import XCTest
@testable import Kiwi

final class ScanViewModelTests: XCTestCase {

    func testInitialState() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let limiter = ClientRateLimiter(defaults: defaults)

        // Create a minimal API client for testing
        let keychainHelper = KeychainHelper()
        let interceptor = AuthInterceptor(keychainHelper: keychainHelper)
        let client = APIClient(
            baseURL: URL(string: "https://test.example.com")!,
            authInterceptor: interceptor
        )

        let viewModel = ScanViewModel(
            getQuotaUseCase: GetQuotaUseCase(apiClient: client),
            rateLimiter: limiter
        )

        XCTAssertNil(viewModel.quota)
        XCTAssertFalse(viewModel.isLoadingQuota)
        XCTAssertNil(viewModel.error)
        XCTAssertNil(viewModel.selectedImage)
        XCTAssertTrue(viewModel.canScan) // Fresh limiter allows scans
        XCTAssertEqual(viewModel.remainingScans, 4)
    }

    func testCanScanReturnsFalseWhenQuotaIsZero() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let limiter = ClientRateLimiter(defaults: defaults)

        // Use up all scans
        for _ in 0..<4 {
            limiter.recordScan()
        }

        let keychainHelper = KeychainHelper()
        let interceptor = AuthInterceptor(keychainHelper: keychainHelper)
        let client = APIClient(
            baseURL: URL(string: "https://test.example.com")!,
            authInterceptor: interceptor
        )

        let viewModel = ScanViewModel(
            getQuotaUseCase: GetQuotaUseCase(apiClient: client),
            rateLimiter: limiter
        )

        XCTAssertFalse(viewModel.canScan)
        XCTAssertEqual(viewModel.remainingScans, 0)
    }

    func testSelectImageSetsProperty() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let limiter = ClientRateLimiter(defaults: defaults)

        let keychainHelper = KeychainHelper()
        let interceptor = AuthInterceptor(keychainHelper: keychainHelper)
        let client = APIClient(
            baseURL: URL(string: "https://test.example.com")!,
            authInterceptor: interceptor
        )

        let viewModel = ScanViewModel(
            getQuotaUseCase: GetQuotaUseCase(apiClient: client),
            rateLimiter: limiter
        )

        let size = CGSize(width: 50, height: 50)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.green.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }

        viewModel.selectImage(image)

        XCTAssertNotNil(viewModel.selectedImage)
    }
}
