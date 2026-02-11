import XCTest
import UIKit
@testable import Kiwi

final class ScanFridgeUseCaseTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocolMock.requestHandler = nil
    }

    func testExecuteReturnsParsedScanResponse() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: config)

        URLProtocolMock.requestHandler = { request in
            let json = """
            {
              "ingredients": [
                {
                  "id": "11111111-1111-4111-8111-111111111111",
                  "name": "Eggs",
                  "category": "Protein",
                  "confidence": 0.9
                }
              ],
              "recipes": []
            }
            """.data(using: .utf8)!

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!

            return (response, json)
        }

        let apiClient = APIClient(session: session)
        let useCase = ScanFridgeUseCase(apiClient: apiClient)

        let image = UIImage(systemName: "leaf")!
        let response = try await useCase.execute(image: image)

        XCTAssertEqual(response.ingredients.first?.name, "Eggs")
    }
}

private final class URLProtocolMock: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = URLProtocolMock.requestHandler else {
            XCTFail("Request handler was not set")
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
