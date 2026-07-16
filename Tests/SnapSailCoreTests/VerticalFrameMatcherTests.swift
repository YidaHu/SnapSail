import XCTest
@testable import SnapSailCore

final class VerticalFrameMatcherTests: XCTestCase {
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
}
