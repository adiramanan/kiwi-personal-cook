import UIKit
import ImageIO

struct ImageMetadataStripper: Sendable {
    private let maxSizeBytes: Int
    private let initialQuality: CGFloat

    init(maxSizeBytes: Int = 1_048_576, initialQuality: CGFloat = 0.8) {
        self.maxSizeBytes = maxSizeBytes
        self.initialQuality = initialQuality
    }

    func strip(image: UIImage) throws -> Data {
        guard let cgImage = image.cgImage else {
            throw ImageProcessingError.invalidImage
        }

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData, "public.jpeg" as CFString, 1, nil
        ) else {
            throw ImageProcessingError.compressionFailed
        }

        // Write without any metadata properties — strips EXIF, GPS, TIFF
        CGImageDestinationAddImage(destination, cgImage, [:] as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ImageProcessingError.compressionFailed
        }

        var data = mutableData as Data

        // Iteratively reduce quality if over max size
        var quality = initialQuality
        while data.count > maxSizeBytes && quality > 0.1 {
            quality -= 0.1
            guard let compressed = UIImage(data: data)?.jpegData(compressionQuality: quality) else { break }
            data = compressed
        }

        if data.count > maxSizeBytes {
            throw ImageProcessingError.imageTooLarge
        }

        return data
    }
}

enum ImageProcessingError: Error, Sendable {
    case invalidImage
    case compressionFailed
    case imageTooLarge
}
