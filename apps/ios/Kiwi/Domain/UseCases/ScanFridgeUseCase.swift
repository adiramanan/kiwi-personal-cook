import UIKit

struct ScanFridgeUseCase: Sendable {
    let apiClient: APIClient
    let metadataStripper: ImageMetadataStripper

    init(apiClient: APIClient = .shared, metadataStripper: ImageMetadataStripper = .init()) {
        self.apiClient = apiClient
        self.metadataStripper = metadataStripper
    }

    func execute(image: UIImage) async throws -> ScanResponse {
        let cleanData = try metadataStripper.strip(image: image)
        return try await apiClient.upload(.scan, imageData: cleanData)
    }
}
