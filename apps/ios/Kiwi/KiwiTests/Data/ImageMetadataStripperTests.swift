import XCTest
import UIKit
import ImageIO
@testable import Kiwi

final class ImageMetadataStripperTests: XCTestCase {
    func testStripMetadataRemovesEXIFGPSAndTIFF() throws {
        let image = UIImage(systemName: "leaf")!
        let imageWithMetadataData = try addMetadata(to: image)
        let imageWithMetadata = try XCTUnwrap(UIImage(data: imageWithMetadataData))

        let stripper = ImageMetadataStripper()
        let output = try stripper.stripMetadata(from: imageWithMetadata)

        let source = try XCTUnwrap(CGImageSourceCreateWithData(output as CFData, nil))
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]

        XCTAssertNil(properties?[kCGImagePropertyExifDictionary])
        XCTAssertNil(properties?[kCGImagePropertyGPSDictionary])
        XCTAssertNil(properties?[kCGImagePropertyTIFFDictionary])
    }

    private func addMetadata(to image: UIImage) throws -> Data {
        let data = try XCTUnwrap(image.jpegData(compressionQuality: 1.0))
        let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
        let type = try XCTUnwrap(CGImageSourceGetType(source))

        let mutableData = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(mutableData, type, 1, nil))

        let metadata: [CFString: Any] = [
            kCGImagePropertyExifDictionary: [kCGImagePropertyExifUserComment: "test"],
            kCGImagePropertyGPSDictionary: [kCGImagePropertyGPSLatitude: 37.0],
            kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFMake: "Kiwi"],
        ]

        CGImageDestinationAddImageFromSource(destination, source, 0, metadata as CFDictionary)
        CGImageDestinationFinalize(destination)

        return mutableData as Data
    }
}
