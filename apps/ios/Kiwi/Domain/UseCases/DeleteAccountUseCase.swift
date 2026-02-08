import Foundation

struct DeleteAccountResponse: Codable {
    let deleted: Bool
}

struct DeleteAccountUseCase {
    let apiClient: APIClient

    func execute() async throws {
        let _: DeleteAccountResponse = try await apiClient.request(.deleteAccount)
    }
}
