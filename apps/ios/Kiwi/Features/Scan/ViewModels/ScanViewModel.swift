import UIKit

@Observable
final class ScanViewModel {
    var quota: QuotaInfo?
    var isLoadingQuota: Bool = false
    var selectedImage: IdentifiableImage?
    var showCamera: Bool = false
    var showPhotoPicker: Bool = false
    var error: APIError?

    private let getQuota = GetQuotaUseCase()
    private let rateLimiter = ClientRateLimiter()

    var canScan: Bool {
        rateLimiter.canScan() && (quota?.remaining ?? 1) > 0
    }

    var remainingScans: Int {
        quota?.remaining ?? rateLimiter.remaining()
    }

    func loadQuota() async {
        isLoadingQuota = true
        defer { isLoadingQuota = false }

        do {
            quota = try await getQuota.execute()
        } catch {
            // Fall back to client-side rate limiter
            quota = nil
        }
    }

    func selectImage(_ image: UIImage) {
        selectedImage = IdentifiableImage(image: image)
        rateLimiter.recordScan()
    }
}
