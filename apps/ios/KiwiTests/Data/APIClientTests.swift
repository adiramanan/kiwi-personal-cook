import XCTest
@testable import Kiwi

final class APIClientTests: XCTestCase {

    func testEndpointPaths() {
        XCTAssertEqual(Endpoint.scan.path, "/v1/scan")
        XCTAssertEqual(Endpoint.quota.path, "/v1/quota")
        XCTAssertEqual(Endpoint.deleteAccount.path, "/v1/account")
        XCTAssertEqual(Endpoint.authApple.path, "/v1/auth/apple")
    }

    func testEndpointMethods() {
        XCTAssertEqual(Endpoint.scan.method, "POST")
        XCTAssertEqual(Endpoint.quota.method, "GET")
        XCTAssertEqual(Endpoint.deleteAccount.method, "DELETE")
        XCTAssertEqual(Endpoint.authApple.method, "POST")
    }

    func testAPIErrorEquality() {
        XCTAssertEqual(APIError.unauthorized, APIError.unauthorized)
        XCTAssertEqual(APIError.decodingError, APIError.decodingError)
        XCTAssertEqual(APIError.invalidResponse, APIError.invalidResponse)
        XCTAssertEqual(APIError.unknown, APIError.unknown)

        let date = Date()
        XCTAssertEqual(
            APIError.rateLimited(retryAfter: date),
            APIError.rateLimited(retryAfter: date)
        )

        XCTAssertEqual(
            APIError.serverError(statusCode: 500, message: "error"),
            APIError.serverError(statusCode: 500, message: "error")
        )

        XCTAssertNotEqual(APIError.unauthorized, APIError.decodingError)
    }

    func testAppErrorFromAPIError() {
        XCTAssertEqual(AppError.from(.unauthorized), .unauthorized)
        XCTAssertEqual(AppError.from(.rateLimited(retryAfter: nil)), .rateLimited)
        XCTAssertEqual(AppError.from(.serverError(statusCode: 500, message: nil)), .server)
        XCTAssertEqual(AppError.from(.networkError(URLError(.notConnectedToInternet))), .network)
        XCTAssertEqual(AppError.from(.decodingError), .invalidData)
        XCTAssertEqual(AppError.from(.invalidResponse), .invalidData)
        XCTAssertEqual(AppError.from(.unknown), .unknown)
    }

    func testAppErrorRetryable() {
        XCTAssertTrue(AppError.network.isRetryable)
        XCTAssertTrue(AppError.server.isRetryable)
        XCTAssertTrue(AppError.invalidData.isRetryable)
        XCTAssertTrue(AppError.unknown.isRetryable)
        XCTAssertFalse(AppError.rateLimited.isRetryable)
        XCTAssertFalse(AppError.unauthorized.isRetryable)
    }

    func testAppErrorMessages() {
        // Ensure all error types have non-empty user-friendly messages
        let allErrors: [AppError] = [.network, .server, .rateLimited, .unauthorized, .invalidData, .unknown]

        for error in allErrors {
            XCTAssertFalse(error.title.isEmpty, "\(error) should have a title")
            XCTAssertFalse(error.message.isEmpty, "\(error) should have a message")
        }
    }
}
