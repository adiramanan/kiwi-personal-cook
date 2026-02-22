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
        if let quota {
            // Server quota is authoritative when available
            return quota.remaining > 0
        }
        // Fall back to client-side limiter only when offline / API unreachable
        return rateLimiter.canScan()
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
