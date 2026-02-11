import XCTest
@testable import Kiwi

final class APIClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        APITestURLProtocol.requestHandler = nil
    }

    func testRequestDecodesQuotaInfo() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [APITestURLProtocol.self]
        let session = URLSession(configuration: config)

        APITestURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")

            let payload = """
            {"remaining":3,"limit":4,"resetsAt":"2026-02-10T00:00:00Z"}
            """.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, payload)
        }

        let client = APIClient(session: session)
        let quota: QuotaInfo = try await client.request(.quota)

        XCTAssertEqual(quota.remaining, 3)
        XCTAssertEqual(quota.limit, 4)
    }

    func testRequestMapsUnauthorized() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [APITestURLProtocol.self]
        let session = URLSession(configuration: config)

        APITestURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let client = APIClient(session: session)

        do {
            let _: QuotaInfo = try await client.request(.quota)
            XCTFail("Expected unauthorized error")
        } catch let error as APIError {
            XCTAssertEqual(error, .unauthorized)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private final class APITestURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = APITestURLProtocol.requestHandler else {
            XCTFail("Missing request handler")
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
