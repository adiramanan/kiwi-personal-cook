import Foundation

struct DeleteAccountUseCase {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func execute() async throws {
        _ = try await apiClient.request(Endpoint.deleteAccount) as EmptyResponse
    }
}

struct EmptyResponse: Decodable {}
