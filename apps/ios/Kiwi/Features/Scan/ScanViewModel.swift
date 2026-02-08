import SwiftUI
import Observation

@Observable
final class ScanViewModel {
    var quota: QuotaInfo?
    var isLoadingQuota: Bool = false
    var error: AppError?
    var selectedImage: UIImage?

    private let getQuotaUseCase: GetQuotaUseCase
    private let rateLimiter: ClientRateLimiter

    init(getQuotaUseCase: GetQuotaUseCase, rateLimiter: ClientRateLimiter = ClientRateLimiter()) {
        self.getQuotaUseCase = getQuotaUseCase
        self.rateLimiter = rateLimiter
    }

    var canScan: Bool {
        if let quota {
            return quota.remaining > 0
        }
        return rateLimiter.canScan()
    }

    var remainingScans: Int {
        quota?.remaining ?? rateLimiter.remaining()
    }

    func loadQuota() async {
        isLoadingQuota = true
        error = nil

        do {
            quota = try await getQuotaUseCase.execute()
        } catch let apiError as APIError {
            error = AppError.from(apiError)
        } catch {
            self.error = .unknown
        }

        isLoadingQuota = false
    }

    func selectImage(_ image: UIImage) {
        selectedImage = image
    }
}
