import UIKit

struct ScanFridgeUseCase {
    let apiClient: APIClient
    let metadataStripper: ImageMetadataStripper

    init(apiClient: APIClient, metadataStripper: ImageMetadataStripper = ImageMetadataStripper()) {
        self.apiClient = apiClient
        self.metadataStripper = metadataStripper
    }

    func execute(image: UIImage) async throws -> ScanResponse {
        // Strip metadata and compress the image
        let imageData = try metadataStripper.stripAndCompress(image: image)

        // Upload to API
        let response: ScanResponse = try await apiClient.upload(.scan, imageData: imageData)
        return response
    }
}
