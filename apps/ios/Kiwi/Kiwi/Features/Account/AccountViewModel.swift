import Foundation
import Observation

@Observable
final class AccountViewModel {
    private let deleteUseCase: DeleteAccountUseCase
    private let appState: AppState

    var isDeleting = false
    var error: AppError?

    init(deleteUseCase: DeleteAccountUseCase = DeleteAccountUseCase(), appState: AppState) {
        self.deleteUseCase = deleteUseCase
        self.appState = appState
    }

    @MainActor
    func deleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await deleteUseCase.execute()
            appState.signOut()
        } catch {
            self.error = .server(message: nil)
        }
    }
}
