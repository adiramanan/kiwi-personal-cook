import XCTest
import ImageIO
@testable import Kiwi

final class ImageMetadataStripperTests: XCTestCase {

    let stripper = ImageMetadataStripper()

    func testStrippedImageContainsNoEXIFMetadata() throws {
        let testImage = createTestImage(size: CGSize(width: 200, height: 200))
        let data = try stripper.stripAndCompress(image: testImage)

        // Inspect metadata using CGImageSource
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            XCTFail("Failed to create image source from stripped data")
            return
        }

        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]

        // Should not contain EXIF data
        let exifKey = kCGImagePropertyExifDictionary as String
        if let exifDict = properties?[exifKey] as? [String: Any] {
            XCTAssertTrue(exifDict.isEmpty, "EXIF dictionary should be empty after stripping")
        }

        // Should not contain GPS data
        let gpsKey = kCGImagePropertyGPSDictionary as String
        if let gpsDict = properties?[gpsKey] as? [String: Any] {
            XCTAssertTrue(gpsDict.isEmpty, "GPS dictionary should be empty after stripping")
        }

        // Should not contain TIFF metadata
        let tiffKey = kCGImagePropertyTIFFDictionary as String
        if let tiffDict = properties?[tiffKey] as? [String: Any] {
            XCTAssertTrue(tiffDict.isEmpty, "TIFF dictionary should be empty after stripping")
        }
    }

    func testOutputIsValidJPEG() throws {
        let testImage = createTestImage(size: CGSize(width: 100, height: 100))
        let data = try stripper.stripAndCompress(image: testImage)

        let bytes = [UInt8](data)
        XCTAssertGreaterThanOrEqual(bytes.count, 3)
        XCTAssertEqual(bytes[0], 0xFF, "JPEG should start with FF")
        XCTAssertEqual(bytes[1], 0xD8, "JPEG second byte should be D8")
        XCTAssertEqual(bytes[2], 0xFF, "JPEG third byte should be FF")
    }

    func testOutputIsUnder1MB() throws {
        let testImage = createTestImage(size: CGSize(width: 100, height: 100))
        let data = try stripper.stripAndCompress(image: testImage)

        XCTAssertLessThanOrEqual(data.count, 1_024 * 1_024)
    }

    func testOutputIsNonEmpty() throws {
        let testImage = createTestImage(size: CGSize(width: 50, height: 50))
        let data = try stripper.stripAndCompress(image: testImage)

        XCTAssertFalse(data.isEmpty)
    }

    // MARK: - Helpers

    private func createTestImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}
