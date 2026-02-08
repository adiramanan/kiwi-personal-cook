import XCTest
@testable import Kiwi

final class AccountViewModelTests: XCTestCase {

    func testInitialState() {
        let keychainHelper = KeychainHelper()
        let interceptor = AuthInterceptor(keychainHelper: keychainHelper)
        let client = APIClient(
            baseURL: URL(string: "https://test.example.com")!,
            authInterceptor: interceptor
        )

        let viewModel = AccountViewModel(
            deleteAccountUseCase: DeleteAccountUseCase(apiClient: client),
            appState: AppState()
        )

        XCTAssertFalse(viewModel.isDeleting)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.showDeleteConfirmation)
    }
}
