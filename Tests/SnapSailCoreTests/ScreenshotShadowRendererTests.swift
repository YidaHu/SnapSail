import CoreGraphics
import XCTest
@testable import SnapSailCore

final class ScreenshotShadowRendererTests: XCTestCase {
    func testAddsTransparentPaddingAndVisibleShadowWithoutChangingContent() throws {
        let source = TestImageFactory.patternedImage(width: 100, rows: 0..<60)
        let rendered = try XCTUnwrap(ScreenshotShadowRenderer.render(
            source,
            padding: 20,
            blur: 10,
            offset: CGSize(width: 0, height: -4)
        ))

        XCTAssertEqual(rendered.width, 140)
        XCTAssertEqual(rendered.height, 100)

        let sourceBytes = TestImageFactory.rgba(source)
        let outputBytes = TestImageFactory.rgba(rendered)
        XCTAssertEqual(pixel(outputBytes, width: 140, x: 0, y: 0).alpha, 0)

        let centerSource = pixel(sourceBytes, width: 100, x: 50, y: 30)
        let centerOutput = pixel(outputBytes, width: 140, x: 70, y: 50)
        XCTAssertEqual(centerOutput.red, centerSource.red)
        XCTAssertEqual(centerOutput.green, centerSource.green)
        XCTAssertEqual(centerOutput.blue, centerSource.blue)
        XCTAssertEqual(centerOutput.alpha, 255)

        var hasVisibleShadow = false
        for y in 1..<99 where !hasVisibleShadow {
            for x in 1..<139 {
                let insideImage = (20..<120).contains(x) && (20..<80).contains(y)
                if !insideImage, pixel(outputBytes, width: 140, x: x, y: y).alpha > 0 {
                    hasVisibleShadow = true
                    break
                }
            }
        }
        XCTAssertTrue(hasVisibleShadow)
    }

    private func pixel(_ bytes: [UInt8], width: Int, x: Int, y: Int) -> (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        let offset = (y * width + x) * 4
        return (bytes[offset], bytes[offset + 1], bytes[offset + 2], bytes[offset + 3])
    }
}
