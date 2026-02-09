import Foundation
import Observation
import UIKit

@Observable
final class ScanViewModel {
    private let getQuotaUseCase: GetQuotaUseCase

    var quota: QuotaInfo?
    var isLoadingQuota = false
    var error: AppError?

    init(getQuotaUseCase: GetQuotaUseCase = GetQuotaUseCase()) {
        self.getQuotaUseCase = getQuotaUseCase
    }

    @MainActor
    func loadQuota() async {
        isLoadingQuota = true
        defer { isLoadingQuota = false }
        do {
            quota = try await getQuotaUseCase.execute()
        } catch {
            self.error = .network
        }
    }

    func selectImage(_ image: UIImage) {
        // Navigation handled by view.
    }
}
