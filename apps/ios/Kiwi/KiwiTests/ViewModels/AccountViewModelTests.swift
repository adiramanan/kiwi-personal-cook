import XCTest
@testable import Kiwi

@MainActor
final class AccountViewModelTests: XCTestCase {
    func testDeleteAccountSignsOutOnSuccess() async {
        let appState = AppState()
        appState.isAuthenticated = true
        appState.sessionToken = "token"

        let session = makeTestSession { request in
            XCTAssertEqual(request.httpMethod, "DELETE")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, "{}".data(using: .utf8)!)
        }
        let useCase = DeleteAccountUseCase(apiClient: APIClient(session: session))
        let viewModel = AccountViewModel(deleteUseCase: useCase, appState: appState)

        await viewModel.deleteAccount()

        XCTAssertFalse(appState.isAuthenticated)
        XCTAssertNil(appState.sessionToken)
        XCTAssertNil(viewModel.error)
    }

    func testDeleteAccountSetsErrorOnFailure() async {
        enum TestError: Error { case failed }

        let appState = AppState()
        appState.isAuthenticated = true

        let session = makeTestSession { request in
            XCTAssertEqual(request.httpMethod, "DELETE")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        let useCase = DeleteAccountUseCase(apiClient: APIClient(session: session))
        let viewModel = AccountViewModel(deleteUseCase: useCase, appState: appState)

        await viewModel.deleteAccount()

        XCTAssertEqual(viewModel.error, .server(message: nil))
        XCTAssertTrue(appState.isAuthenticated)
    }
}
