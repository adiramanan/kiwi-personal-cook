import Foundation
import Observation

@Observable
final class AccountViewModel {
    var isDeleting: Bool = false
    var error: AppError?
    var showDeleteConfirmation: Bool = false

    private let deleteAccountUseCase: DeleteAccountUseCase
    private let appState: AppState

    init(deleteAccountUseCase: DeleteAccountUseCase, appState: AppState) {
        self.deleteAccountUseCase = deleteAccountUseCase
        self.appState = appState
    }

    func deleteAccount() async throws {
        isDeleting = true
        error = nil

        do {
            try await deleteAccountUseCase.execute()
            await MainActor.run {
                appState.signOut()
            }
        } catch let apiError as APIError {
            error = AppError.from(apiError)
            isDeleting = false
            throw apiError
        } catch {
            self.error = .unknown
            isDeleting = false
            throw error
        }
    }
}
