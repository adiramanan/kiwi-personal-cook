import Foundation
import UIKit

struct ScanFridgeUseCase {
    private let apiClient: APIClient
    private let metadataStripper: ImageMetadataStripper

    init(apiClient: APIClient = APIClient(), metadataStripper: ImageMetadataStripper = ImageMetadataStripper()) {
        self.apiClient = apiClient
        self.metadataStripper = metadataStripper
    }

    func execute(image: UIImage) async throws -> ScanResponse {
        let data = try metadataStripper.stripMetadata(from: image)
        let endpoint = Endpoint.scan
        return try await apiClient.upload(endpoint, imageData: data)
    }
}
