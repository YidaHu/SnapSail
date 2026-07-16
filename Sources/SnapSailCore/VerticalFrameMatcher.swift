import CoreGraphics
import Foundation

public struct VerticalFrameMatch: Equatable {
    public let shift: Int
    public let confidence: Double
    public let evaluatedCandidates: Int

    public init(shift: Int, confidence: Double, evaluatedCandidates: Int = 0) {
        self.shift = shift
        self.confidence = confidence
        self.evaluatedCandidates = evaluatedCandidates
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
        func score(for shift: Int, fine: Bool) -> Double? {
            let overlap = height - shift
            guard overlap > topMargin * 2 else { return nil }
            var difference = 0.0
            var sampleCount = 0
            let xStride = fine ? max(sampleStride, previous.width / 120) : max(sampleStride, previous.width / 32)
            let yStride = fine ? max(sampleStride, overlap / 80) : max(sampleStride, overlap / 8)
            for y in stride(from: topMargin, to: overlap - topMargin, by: yStride) {
                for x in stride(from: xMargin, to: previous.width - xMargin, by: xStride) {
                    let a = previousBuffer.gray(x: x, y: y + shift)
                    let b = currentBuffer.gray(x: x, y: y)
                    difference += Double(abs(a - b))
                    sampleCount += 1
                }
            }
            return sampleCount > 0 ? difference / Double(sampleCount) : nil
        }

        let coarseWinners = (minimumShift...maximumShift)
            .compactMap { shift -> (Int, Double)? in
                score(for: shift, fine: false).map { (shift, $0) }
            }
            .sorted { $0.1 < $1.1 }
            .prefix(6)

        var evaluated = Set<Int>()
        for winner in coarseWinners {
            for shift in max(minimumShift, winner.0 - 2)...min(maximumShift, winner.0 + 2) {
                evaluated.insert(shift)
            }
        }

        var bestShift = 0
        var bestScore = Double.greatestFiniteMagnitude
        for shift in evaluated.sorted() {
            evaluated.insert(shift)
            if let candidateScore = score(for: shift, fine: true), candidateScore < bestScore {
                bestScore = candidateScore
                bestShift = shift
            }
        }

        guard bestShift > 0, bestScore <= acceptanceScore else { return nil }
        return VerticalFrameMatch(
            shift: bestShift,
            confidence: max(0, min(1, 1 - bestScore / max(acceptanceScore, 0.001))),
            evaluatedCandidates: evaluated.count
        )
    }
}
