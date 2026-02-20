import Foundation

@Observable
final class AccountViewModel {
    var isDeleting: Bool = false
    var showDeleteConfirmation: Bool = false
    var error: APIError?

    private let deleteAccountUseCase: DeleteAccountUseCase

    init(deleteAccountUseCase: DeleteAccountUseCase = .init()) {
        self.deleteAccountUseCase = deleteAccountUseCase
    }

    func deleteAccount() async throws {
        isDeleting = true
        defer { isDeleting = false }
        try await deleteAccountUseCase.execute()
    }
}
