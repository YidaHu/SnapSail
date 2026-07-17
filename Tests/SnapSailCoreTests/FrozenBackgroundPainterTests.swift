import AppKit
import XCTest
@testable import SnapSail

final class FrozenBackgroundPainterTests: XCTestCase {
    func testDrawsFrozenBackgroundOnlyInsideRequestedClip() throws {
        let size = NSSize(width: 10, height: 10)
        let frozen = solidImage(size: size, color: NSColor(deviceRed: 1, green: 0, blue: 0, alpha: 1))
        let canvas = solidImage(size: size, color: .white)

        canvas.lockFocus()
        FrozenBackgroundPainter.draw(
            frozen,
            in: CGRect(origin: .zero, size: size),
            clippedTo: CGRect(x: 3, y: 3, width: 4, height: 4)
        )
        canvas.unlockFocus()

        let bitmap = try XCTUnwrap(NSBitmapImageRep(data: try XCTUnwrap(canvas.tiffRepresentation)))
        let image = try XCTUnwrap(bitmap.cgImage)
        let bytes = TestImageFactory.rgba(image)

        XCTAssertEqual(
            pixel(in: bytes, width: image.width, x: image.width / 2, y: image.height / 2),
            [255, 0, 0, 255]
        )
        XCTAssertEqual(pixel(in: bytes, width: image.width, x: 1, y: 1), [255, 255, 255, 255])
    }

    private func solidImage(size: NSSize, color: NSColor) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        color.setFill()
        CGRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return image
    }

    private func pixel(in bytes: [UInt8], width: Int, x: Int, y: Int) -> [UInt8] {
        let offset = (y * width + x) * 4
        return Array(bytes[offset..<(offset + 4)])
    }
}
