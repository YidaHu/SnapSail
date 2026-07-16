import XCTest
@testable import SnapSailCore

final class VerticalFrameMatcherTests: XCTestCase {
    func testRejectsIdenticalStaticFramesEvenWhenContentIsUniform() throws {
        let frame = try XCTUnwrap(solidImage(width: 24, height: 24, gray: 238))
        let matcher = VerticalFrameMatcher(
            minimumShift: 1,
            maximumShiftRatio: 0.75,
            sampleStride: 1,
            acceptanceScore: 2
        )

        XCTAssertNil(matcher.match(previous: frame, current: frame))
    }

    func testRejectsStaticFramesWithTinyAnimatedRegion() throws {
        let previous = try XCTUnwrap(solidImage(width: 24, height: 24, gray: 238))
        let current = try XCTUnwrap(solidImage(
            width: 24,
            height: 24,
            gray: 238,
            changedPixel: (x: 12, y: 12, gray: 32)
        ))
        let matcher = VerticalFrameMatcher(
            minimumShift: 1,
            maximumShiftRatio: 0.75,
            sampleStride: 1,
            acceptanceScore: 2
        )

        XCTAssertNil(matcher.match(previous: previous, current: current))
    }

    func testFindsNewVerticalContentHeight() throws {
        let previous = TestImageFactory.patternedImage(width: 12, rows: 0..<12)
        let current = TestImageFactory.patternedImage(width: 12, rows: 4..<16)
        let matcher = VerticalFrameMatcher(
            minimumShift: 1,
            maximumShiftRatio: 0.75,
            sampleStride: 1,
            acceptanceScore: 2
        )

        let match = try XCTUnwrap(matcher.match(previous: previous, current: current))

        XCTAssertEqual(match.shift, 4)
        XCTAssertGreaterThan(match.confidence, 0.99)
        XCTAssertGreaterThan(match.evaluatedCandidates, 0)
    }

    func testRejectsUnrelatedFrames() {
        let previous = TestImageFactory.patternedImage(width: 12, rows: 0..<12)
        let current = TestImageFactory.patternedImage(width: 12, rows: 50..<62)
        let matcher = VerticalFrameMatcher(
            minimumShift: 1,
            maximumShiftRatio: 0.75,
            sampleStride: 1,
            acceptanceScore: 2
        )

        XCTAssertNil(matcher.match(previous: previous, current: current))
    }

    func testUsesBoundedCandidateSearchForLargeFrames() throws {
        let previous = TestImageFactory.patternedImage(width: 1_200, rows: 0..<800)
        let current = TestImageFactory.patternedImage(width: 1_200, rows: 96..<896)
        let matcher = VerticalFrameMatcher(
            minimumShift: 3,
            maximumShiftRatio: 0.72,
            sampleStride: 5,
            acceptanceScore: 2
        )

        let match = try XCTUnwrap(matcher.match(previous: previous, current: current))

        XCTAssertEqual(match.shift, 96)
        XCTAssertGreaterThan(match.confidence, 0.9)
        XCTAssertLessThan(match.evaluatedCandidates, 120)
    }

    private func solidImage(
        width: Int,
        height: Int,
        gray: UInt8,
        changedPixel: (x: Int, y: Int, gray: UInt8)? = nil
    ) -> CGImage? {
        var bytes = [UInt8]()
        bytes.reserveCapacity(width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                var pixelGray = gray
                if let changedPixel,
                   changedPixel.x == x,
                   changedPixel.y == y {
                    pixelGray = changedPixel.gray
                }
                bytes.append(contentsOf: [pixelGray, pixelGray, pixelGray, 255])
            }
        }
        return RGBAImageBuffer(width: width, height: height, bytes: bytes).makeImage()
    }
}
