import Foundation
import ImageIO
import UIKit

struct ImageMetadataStripper {
    func stripMetadata(from image: UIImage) throws -> Data {
        guard let baseData = image.jpegData(compressionQuality: 0.9) else {
            throw AppError.invalidResponse
        }
        let cleaned = removeMetadata(from: baseData)
        return compressToLimit(data: cleaned, maxBytes: 1_000_000)
    }

    private func removeMetadata(from data: Data) -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source) else {
            return data
        }
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData, type, 1, nil) else {
            return data
        }
        CGImageDestinationAddImageFromSource(destination, source, 0, [:] as CFDictionary)
        CGImageDestinationFinalize(destination)
        return mutableData as Data
    }

    private func compressToLimit(data: Data, maxBytes: Int) -> Data {
        guard data.count > maxBytes, let image = UIImage(data: data) else {
            return data
        }
        var quality: CGFloat = 0.9
        var output = data
        while output.count > maxBytes && quality > 0.1 {
            if let compressed = image.jpegData(compressionQuality: quality) {
                output = compressed
            }
            quality -= 0.1
        }
        return output
    }
}
