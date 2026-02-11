import XCTest
@testable import Kiwi

@MainActor
final class AccountViewModelTests: XCTestCase {
    func testDeleteAccountSignsOutOnSuccess() async {
        let appState = AppState()
        appState.isAuthenticated = true
        appState.sessionToken = "token"

        let useCase = DeleteAccountUseCase(executeImpl: {})
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

        let useCase = DeleteAccountUseCase(executeImpl: {
            throw TestError.failed
        })
        let viewModel = AccountViewModel(deleteUseCase: useCase, appState: appState)

        await viewModel.deleteAccount()

        XCTAssertEqual(viewModel.error, .server(message: nil))
        XCTAssertTrue(appState.isAuthenticated)
    }
}
