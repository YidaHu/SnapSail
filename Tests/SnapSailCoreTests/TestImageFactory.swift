import CoreGraphics
import Foundation

enum TestImageFactory {
    static func patternedImage(width: Int, rows: Range<Int>) -> CGImage {
        var bytes = [UInt8](repeating: 0, count: width * rows.count * 4)
        for localY in 0..<rows.count {
            let globalY = rows.lowerBound + localY
            for x in 0..<width {
                let offset = (localY * width + x) * 4
                bytes[offset] = UInt8((globalY * 31 + x * 17) % 251)
                bytes[offset + 1] = UInt8((globalY * 47 + x * 13) % 253)
                bytes[offset + 2] = UInt8((globalY * 61 + x * 7) % 255)
                bytes[offset + 3] = 255
            }
        }

        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        return CGImage(
            width: width,
            height: rows.count,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
    }

    static func rgba(_ image: CGImage) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let context = CGContext(
            data: &bytes,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: image.width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return bytes
    }
}
