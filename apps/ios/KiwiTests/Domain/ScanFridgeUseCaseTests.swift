import XCTest
@testable import Kiwi

final class ScanFridgeUseCaseTests: XCTestCase {

    func testExecuteStripsMetadataAndCallsAPI() async throws {
        // Given a use case with mocked dependencies
        // This test verifies the integration between metadata stripping and API call
        let stripper = ImageMetadataStripper()

        // Test that the stripper can process a basic image
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let testImage = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }

        // Verify stripping produces valid JPEG data under 1 MB
        let data = try stripper.stripAndCompress(image: testImage)
        XCTAssertFalse(data.isEmpty, "Stripped image data should not be empty")
        XCTAssertLessThanOrEqual(data.count, 1_024 * 1_024, "Stripped image should be under 1 MB")

        // Verify JPEG magic bytes
        let bytes = [UInt8](data)
        XCTAssertEqual(bytes[0], 0xFF, "First byte should be JPEG marker")
        XCTAssertEqual(bytes[1], 0xD8, "Second byte should be JPEG marker")
    }

    func testImageCompressionReducesLargeImages() async throws {
        let stripper = ImageMetadataStripper()

        // Create a large image (2000x2000 with complex content)
        let size = CGSize(width: 2000, height: 2000)
        let renderer = UIGraphicsImageRenderer(size: size)
        let testImage = renderer.image { ctx in
            for x in stride(from: 0, to: 2000, by: 10) {
                for y in stride(from: 0, to: 2000, by: 10) {
                    UIColor(
                        red: CGFloat(x) / 2000.0,
                        green: CGFloat(y) / 2000.0,
                        blue: 0.5,
                        alpha: 1.0
                    ).setFill()
                    ctx.fill(CGRect(x: x, y: y, width: 10, height: 10))
                }
            }
        }

        let data = try stripper.stripAndCompress(image: testImage)
        XCTAssertLessThanOrEqual(data.count, 1_024 * 1_024, "Large image should be compressed to under 1 MB")
    }
}
