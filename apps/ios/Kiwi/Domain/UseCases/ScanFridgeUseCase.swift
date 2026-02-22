import UIKit

struct ScanFridgeUseCase: Sendable {
    let apiClient: APIClient
    private let imagePreprocessor: @Sendable (UIImage) throws -> Data

    init(apiClient: APIClient = .shared, metadataStripper: ImageMetadataStripper = .init()) {
        self.apiClient = apiClient
        self.imagePreprocessor = { image in
            try metadataStripper.strip(image: image)
        }
    }

    init(
        apiClient: APIClient = .shared,
        imagePreprocessor: @escaping @Sendable (UIImage) throws -> Data
    ) {
        self.apiClient = apiClient
        self.imagePreprocessor = imagePreprocessor
    }

    func execute(image: UIImage) async throws -> ScanResponse {
        debugLog("Scan pipeline started. inputSize=\(Int(image.size.width))x\(Int(image.size.height))")

        let cleanData: Data
        do {
            cleanData = try imagePreprocessor(image)
            debugLog("Image preprocessing succeeded. bytes=\(cleanData.count)")
        } catch let error as ImageProcessingError {
            let mappedError = mapProcessingError(error)
            debugLog("Image preprocessing failed. type=\(processingErrorName(error)) mappedError=\(mappedError)")
            throw mappedError
        } catch {
            debugLogUnexpectedError(stage: "Image preprocessing failed unexpectedly", error: error)
            throw APIError.unknown
        }

        do {
            return try await apiClient.upload(.scan, imageData: cleanData)
        } catch let apiError as APIError {
            debugLog("Scan upload failed with APIError=\(apiError)")
            throw apiError
        } catch {
            debugLogUnexpectedError(stage: "Scan upload failed unexpectedly", error: error)
            throw APIError.unknown
        }
    }

    private func mapProcessingError(_ error: ImageProcessingError) -> APIError {
        switch error {
        case .invalidImage:
            return .imageProcessingInvalid
        case .imageTooLarge:
            return .imageProcessingTooLarge
        case .compressionFailed:
            return .imageProcessingCompressionFailed
        }
    }

    private func processingErrorName(_ error: ImageProcessingError) -> String {
        switch error {
        case .invalidImage:
            return "invalidImage"
        case .imageTooLarge:
            return "imageTooLarge"
        case .compressionFailed:
            return "compressionFailed"
        }
    }

    private func debugLogUnexpectedError(stage: String, error: Error) {
#if DEBUG
        let nsError = error as NSError
        print(
            "[ScanFridgeUseCase] \(stage). " +
            "type=\(String(reflecting: type(of: error))) " +
            "domain=\(nsError.domain) code=\(nsError.code) " +
            "description=\(nsError.localizedDescription)"
        )
#endif
    }

    private func debugLog(_ message: String) {
#if DEBUG
        print("[ScanFridgeUseCase] \(message)")
#endif
    }
}
