import XCTest
import UIKit
@testable import Kiwi

@MainActor
final class ScanViewModelTests: XCTestCase {
    func testLoadQuotaSuccess() async {
        let payload = """
        {"remaining":3,"limit":4,"resetsAt":"2026-02-10T00:00:00Z"}
        """.data(using: .utf8)!
        let session = makeTestSession { request in
            XCTAssertEqual(request.httpMethod, "GET")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, payload)
        }
        let useCase = GetQuotaUseCase(apiClient: APIClient(session: session))
        let viewModel = ScanViewModel(getQuotaUseCase: useCase)

        await viewModel.loadQuota()

        XCTAssertEqual(viewModel.quota?.remaining, 3)
        XCTAssertNil(viewModel.error)
    }

    func testLoadQuotaFailureSetsError() async {
        let session = makeTestSession { request in
            XCTAssertEqual(request.httpMethod, "GET")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        let useCase = GetQuotaUseCase(apiClient: APIClient(session: session))
        let viewModel = ScanViewModel(getQuotaUseCase: useCase)

        await viewModel.loadQuota()

        XCTAssertEqual(viewModel.error, .network)
    }

    func testSelectImageDoesNotSetError() {
        let payload = """
        {"remaining":4,"limit":4,"resetsAt":"2026-02-10T00:00:00Z"}
        """.data(using: .utf8)!
        let session = makeTestSession { request in
            XCTAssertEqual(request.httpMethod, "GET")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, payload)
        }
        let useCase = GetQuotaUseCase(apiClient: APIClient(session: session))
        let viewModel = ScanViewModel(getQuotaUseCase: useCase)

        viewModel.selectImage(UIImage(systemName: "leaf")!)
        XCTAssertNil(viewModel.error)
    }
}
