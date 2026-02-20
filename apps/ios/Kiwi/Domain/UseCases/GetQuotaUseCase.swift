import Foundation

struct GetQuotaUseCase: Sendable {
    let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func execute() async throws -> QuotaInfo {
        try await apiClient.request(.quota)
    }
}
