import UIKit
import ImageIO

struct ImageMetadataStripper {
    private let maxSizeBytes: Int = 1_024 * 1_024  // 1 MB

    enum MetadataError: Error {
        case failedToCreateImageSource
        case failedToCreateImageDestination
        case failedToFinalize
        case failedToCompress
    }

    /// Strips all metadata from the image and compresses to JPEG under 1 MB.
    func stripAndCompress(image: UIImage) throws -> Data {
        // Step 1: Initial JPEG encoding (strips most EXIF by default)
        guard let initialData = image.jpegData(compressionQuality: 0.8) else {
            throw MetadataError.failedToCompress
        }

        // Step 2: Use CGImageSource/Destination to create a clean image without any metadata
        let cleanData = try stripMetadataProperties(from: initialData)

        // Step 3: If the image is still over 1 MB, reduce quality iteratively
        if cleanData.count <= maxSizeBytes {
            return cleanData
        }

        return try compressToMaxSize(image: image)
    }

    /// Uses CGImageSource + CGImageDestination to strip all metadata properties.
    private func stripMetadataProperties(from data: Data) throws -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw MetadataError.failedToCreateImageSource
        }

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData as CFMutableData,
            "public.jpeg" as CFString,
            1,
            nil
        ) else {
            throw MetadataError.failedToCreateImageDestination
        }

        // Add the image without any metadata properties
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.8,
            kCGImagePropertyExifDictionary: [:] as CFDictionary,
            kCGImagePropertyGPSDictionary: [:] as CFDictionary,
            kCGImagePropertyTIFFDictionary: [:] as CFDictionary,
            kCGImagePropertyIPTCDictionary: [:] as CFDictionary,
        ]

        CGImageDestinationAddImageFromSource(destination, source, 0, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw MetadataError.failedToFinalize
        }

        return mutableData as Data
    }

    /// Iteratively reduces compression quality to get under maxSizeBytes.
    private func compressToMaxSize(image: UIImage) throws -> Data {
        var quality: CGFloat = 0.7

        while quality > 0.1 {
            if let data = image.jpegData(compressionQuality: quality) {
                let cleaned = try stripMetadataProperties(from: data)
                if cleaned.count <= maxSizeBytes {
                    return cleaned
                }
            }
            quality -= 0.1
        }

        // Last resort: lowest quality
        guard let data = image.jpegData(compressionQuality: 0.1) else {
            throw MetadataError.failedToCompress
        }

        return try stripMetadataProperties(from: data)
    }
}
