import Foundation

struct GetQuotaUseCase {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func execute() async throws -> QuotaInfo {
        try await apiClient.request(.quota)
    }
}
