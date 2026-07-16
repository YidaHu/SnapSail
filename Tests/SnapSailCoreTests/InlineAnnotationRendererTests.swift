import AppKit
import XCTest
@testable import SnapSail
@testable import SnapSailCore

final class InlineAnnotationRendererTests: XCTestCase {
    func testPixelationPreviewNeverUsesTheSelectedAnnotationColor() throws {
        let canvasSize = NSSize(width: 80, height: 80)
        let annotation = InlineAnnotation(
            tool: .pixelate,
            start: CGPoint(x: 0.1, y: 0.1),
            end: CGPoint(x: 0.9, y: 0.9),
            color: .red
        )
        let preview = NSImage(size: canvasSize)

        preview.lockFocus()
        NSColor.clear.setFill()
        CGRect(origin: .zero, size: canvasSize).fill(using: .copy)
        InlineAnnotationRenderer.draw(
            annotations: [annotation],
            draft: nil,
            in: CGRect(origin: .zero, size: canvasSize)
        )
        preview.unlockFocus()

        let bitmap = try XCTUnwrap(NSBitmapImageRep(data: try XCTUnwrap(preview.tiffRepresentation)))
        let image = try XCTUnwrap(bitmap.cgImage)
        let bytes = TestImageFactory.rgba(image)
        let containsRedGridPixel = stride(from: 0, to: bytes.count, by: 4).contains { offset in
            let red = Int(bytes[offset])
            let green = Int(bytes[offset + 1])
            let blue = Int(bytes[offset + 2])
            let alpha = Int(bytes[offset + 3])
            return alpha > 0 && red > green + 40 && red > blue + 40
        }

        XCTAssertFalse(containsRedGridPixel)
    }

    func testPixelationPreviewUsesPixelsFromTheCapturedSelection() throws {
        let canvasSize = NSSize(width: 80, height: 80)
        let annotation = InlineAnnotation(
            tool: .pixelate,
            start: CGPoint(x: 0.1, y: 0.1),
            end: CGPoint(x: 0.9, y: 0.9),
            color: .red
        )
        let source = try XCTUnwrap(solidImage(width: 80, height: 80, red: 31, green: 97, blue: 151))
        let preview = NSImage(size: canvasSize)

        preview.lockFocus()
        NSColor.clear.setFill()
        CGRect(origin: .zero, size: canvasSize).fill(using: .copy)
        InlineAnnotationRenderer.draw(
            annotations: [annotation],
            draft: nil,
            in: CGRect(origin: .zero, size: canvasSize),
            sourceImage: source
        )
        preview.unlockFocus()

        let bitmap = try XCTUnwrap(NSBitmapImageRep(data: try XCTUnwrap(preview.tiffRepresentation)))
        let image = try XCTUnwrap(bitmap.cgImage)
        let bytes = TestImageFactory.rgba(image)
        let offset = (40 * image.width + 40) * 4

        XCTAssertEqual(Array(bytes[offset..<(offset + 4)]), [31, 97, 151, 255])
    }

    private func solidImage(
        width: Int,
        height: Int,
        red: UInt8,
        green: UInt8,
        blue: UInt8
    ) -> CGImage? {
        var bytes = [UInt8]()
        bytes.reserveCapacity(width * height * 4)
        for _ in 0..<(width * height) {
            bytes.append(contentsOf: [red, green, blue, 255])
        }
        let provider = CGDataProvider(data: Data(bytes) as CFData)
        return provider.flatMap {
            CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: $0,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        }
    }
}
