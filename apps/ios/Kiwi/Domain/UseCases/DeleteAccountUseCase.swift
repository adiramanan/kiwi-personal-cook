import Foundation

struct DeleteAccountUseCase: Sendable {
    let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func execute() async throws {
        try await apiClient.requestVoid(.deleteAccount)
    }
}
