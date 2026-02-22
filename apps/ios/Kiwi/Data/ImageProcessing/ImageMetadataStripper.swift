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

        // Downsample to max 1920px on the long edge before compressing.
        // Compression quality alone cannot get a modern iPhone 12–48MP photo
        // under 1MB; dimension reduction is required.
        let downsampledCGImage = downsample(cgImage)

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData, "public.jpeg" as CFString, 1, nil
        ) else {
            throw ImageProcessingError.compressionFailed
        }

        // Write without metadata (strips EXIF/GPS/TIFF) and apply initial
        // quality on the first write — empty [:] produces lossless output.
        let props: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: initialQuality
        ]
        CGImageDestinationAddImage(destination, downsampledCGImage, props as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ImageProcessingError.compressionFailed
        }

        var data = mutableData as Data

        // Iteratively reduce quality further if still over limit
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

    // MARK: - Private

    private func downsample(_ cgImage: CGImage, maxDimension: CGFloat = 1920) -> CGImage {
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let longEdge = max(width, height)

        guard longEdge > maxDimension else { return cgImage }

        let scale = maxDimension / longEdge
        let newWidth = Int(width * scale)
        let newHeight = Int(height * scale)

        let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        ) else { return cgImage }

        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        return context.makeImage() ?? cgImage
    }
}

enum ImageProcessingError: Error, Sendable {
    case invalidImage
    case compressionFailed
    case imageTooLarge
}
