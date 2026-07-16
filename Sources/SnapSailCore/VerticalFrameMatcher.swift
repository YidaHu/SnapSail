import CoreGraphics
import Foundation

public struct VerticalFrameMatch: Equatable {
    public let shift: Int
    public let confidence: Double

    public init(shift: Int, confidence: Double) {
        self.shift = shift
        self.confidence = confidence
    }
}

public struct VerticalFrameMatcher {
    public let minimumShift: Int
    public let maximumShiftRatio: Double
    public let sampleStride: Int
    public let acceptanceScore: Double

    public init(
        minimumShift: Int = 3,
        maximumShiftRatio: Double = 0.72,
        sampleStride: Int = 4,
        acceptanceScore: Double = 14
    ) {
        self.minimumShift = minimumShift
        self.maximumShiftRatio = maximumShiftRatio
        self.sampleStride = max(1, sampleStride)
        self.acceptanceScore = acceptanceScore
    }

    public func match(previous: CGImage, current: CGImage) -> VerticalFrameMatch? {
        guard previous.width == current.width,
              previous.height == current.height,
              let previousBuffer = RGBAImageBuffer(image: previous),
              let currentBuffer = RGBAImageBuffer(image: current) else {
            return nil
        }

        let height = previous.height
        let maximumShift = max(
            minimumShift,
            min(height - 2, Int(Double(height) * maximumShiftRatio))
        )
        guard minimumShift <= maximumShift else { return nil }

        let xMargin = max(0, previous.width / 12)
        let topMargin = max(0, height / 12)
        var bestShift = 0
        var bestScore = Double.greatestFiniteMagnitude

        for shift in minimumShift...maximumShift {
            let overlap = height - shift
            guard overlap > topMargin * 2 else { continue }
            var difference = 0.0
            var sampleCount = 0

            for y in stride(from: topMargin, to: overlap - topMargin, by: sampleStride) {
                for x in stride(from: xMargin, to: previous.width - xMargin, by: sampleStride) {
                    let a = previousBuffer.gray(x: x, y: y + shift)
                    let b = currentBuffer.gray(x: x, y: y)
                    difference += Double(abs(a - b))
                    sampleCount += 1
                }
            }

            guard sampleCount > 0 else { continue }
            let score = difference / Double(sampleCount)
            if score < bestScore {
                bestScore = score
                bestShift = shift
            }
        }

        guard bestShift > 0, bestScore <= acceptanceScore else { return nil }
        return VerticalFrameMatch(
            shift: bestShift,
            confidence: max(0, min(1, 1 - bestScore / max(acceptanceScore, 0.001)))
        )
    }
}
