import CoreGraphics
import Foundation

struct RGBAImageBuffer {
    let width: Int
    let height: Int
    var bytes: [UInt8]

    init?(image: CGImage) {
        width = image.width
        height = image.height
        bytes = [UInt8](repeating: 0, count: width * height * 4)

        guard let context = CGContext(
            data: &bytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.interpolationQuality = .none
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    }

    init(width: Int, height: Int, bytes: [UInt8]) {
        self.width = width
        self.height = height
        self.bytes = bytes
    }

    func gray(x: Int, y: Int) -> Int {
        let offset = (y * width + x) * 4
        return (Int(bytes[offset]) * 77
            + Int(bytes[offset + 1]) * 150
            + Int(bytes[offset + 2]) * 29) >> 8
    }

    func rows(_ range: Range<Int>) -> RGBAImageBuffer {
        let safeLower = max(0, min(height, range.lowerBound))
        let safeUpper = max(safeLower, min(height, range.upperBound))
        let bytesPerRow = width * 4
        let start = safeLower * bytesPerRow
        let end = safeUpper * bytesPerRow
        return RGBAImageBuffer(
            width: width,
            height: safeUpper - safeLower,
            bytes: Array(bytes[start..<end])
        )
    }

    func makeImage() -> CGImage? {
        guard width > 0, height > 0,
              let provider = CGDataProvider(data: Data(bytes) as CFData) else {
            return nil
        }
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}
