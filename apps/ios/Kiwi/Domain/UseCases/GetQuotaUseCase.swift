import Foundation

struct GetQuotaUseCase {
    let apiClient: APIClient

    func execute() async throws -> QuotaInfo {
        let response: QuotaInfo = try await apiClient.request(.quota)
        return response
    }
}
