import CoreGraphics
import Foundation

public enum ScrollAppendResult: Equatable {
    case started(height: Int)
    case appended(rows: Int, totalHeight: Int)
    case noMatch(totalHeight: Int)
    case reachedMaximum(totalHeight: Int)
    case incompatibleFrame(totalHeight: Int)
}

public final class ScrollStitcher {
    private let matcher: VerticalFrameMatcher
    private let maximumHeight: Int
    private var chunks: [RGBAImageBuffer] = []
    private var lastFrame: CGImage?

    public private(set) var totalHeight = 0
    public private(set) var width = 0

    public init(matcher: VerticalFrameMatcher = VerticalFrameMatcher(), maximumHeight: Int = 60_000) {
        self.matcher = matcher
        self.maximumHeight = maximumHeight
    }

    public func append(_ image: CGImage) -> ScrollAppendResult {
        guard let buffer = RGBAImageBuffer(image: image) else {
            return .incompatibleFrame(totalHeight: totalHeight)
        }

        guard let previous = lastFrame else {
            guard image.height <= maximumHeight else {
                return .reachedMaximum(totalHeight: 0)
            }
            width = image.width
            totalHeight = image.height
            chunks = [buffer]
            lastFrame = image
            return .started(height: totalHeight)
        }

        guard image.width == width, image.height == previous.height else {
            return .incompatibleFrame(totalHeight: totalHeight)
        }
        guard let match = matcher.match(previous: previous, current: image) else {
            return .noMatch(totalHeight: totalHeight)
        }
        guard totalHeight + match.shift <= maximumHeight else {
            return .reachedMaximum(totalHeight: totalHeight)
        }

        chunks.append(buffer.rows((buffer.height - match.shift)..<buffer.height))
        totalHeight += match.shift
        lastFrame = image
        return .appended(rows: match.shift, totalHeight: totalHeight)
    }

    public func makeImage() -> CGImage? {
        guard width > 0, totalHeight > 0 else { return nil }
        var joined = [UInt8]()
        joined.reserveCapacity(width * totalHeight * 4)
        for chunk in chunks {
            joined.append(contentsOf: chunk.bytes)
        }
        return RGBAImageBuffer(width: width, height: totalHeight, bytes: joined).makeImage()
    }

    public func reset() {
        chunks.removeAll(keepingCapacity: false)
        lastFrame = nil
        totalHeight = 0
        width = 0
    }
}
