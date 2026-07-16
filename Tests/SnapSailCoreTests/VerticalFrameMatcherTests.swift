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
}
