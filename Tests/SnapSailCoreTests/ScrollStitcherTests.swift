import XCTest
@testable import SnapSailCore

final class ScrollStitcherTests: XCTestCase {
    func testStaticUniformFramesNeverGrowTheLongImage() throws {
        var bytes = [UInt8]()
        bytes.reserveCapacity(24 * 24 * 4)
        for _ in 0..<(24 * 24) {
            bytes.append(contentsOf: [244, 244, 244, 255])
        }
        let frame = try XCTUnwrap(RGBAImageBuffer(
            width: 24,
            height: 24,
            bytes: bytes
        ).makeImage())
        let matcher = VerticalFrameMatcher(
            minimumShift: 1,
            maximumShiftRatio: 0.75,
            sampleStride: 1,
            acceptanceScore: 2
        )
        let stitcher = ScrollStitcher(matcher: matcher, maximumHeight: 100)

        XCTAssertEqual(stitcher.append(frame), .started(height: 24))
        for _ in 0..<20 {
            XCTAssertEqual(stitcher.append(frame), .noMatch(totalHeight: 24))
        }
        XCTAssertEqual(stitcher.totalHeight, 24)
        XCTAssertEqual(try XCTUnwrap(stitcher.makeImage()).height, 24)
    }

    func testAppendsOnlyNewRowsAndBuildsLongImage() throws {
        let first = TestImageFactory.patternedImage(width: 12, rows: 0..<12)
        let second = TestImageFactory.patternedImage(width: 12, rows: 4..<16)
        let matcher = VerticalFrameMatcher(
            minimumShift: 1,
            maximumShiftRatio: 0.75,
            sampleStride: 1,
            acceptanceScore: 2
        )
        let stitcher = ScrollStitcher(matcher: matcher, maximumHeight: 100)

        XCTAssertEqual(stitcher.append(first), .started(height: 12))
        XCTAssertEqual(stitcher.append(second), .appended(rows: 4, totalHeight: 16))

        let result = try XCTUnwrap(stitcher.makeImage())
        let expected = TestImageFactory.patternedImage(width: 12, rows: 0..<16)
        XCTAssertEqual(result.width, 12)
        XCTAssertEqual(result.height, 16)
        XCTAssertEqual(TestImageFactory.rgba(result), TestImageFactory.rgba(expected))
    }

    func testStopsAtMaximumHeightWithoutDamagingExistingImage() throws {
        let first = TestImageFactory.patternedImage(width: 12, rows: 0..<12)
        let second = TestImageFactory.patternedImage(width: 12, rows: 4..<16)
        let matcher = VerticalFrameMatcher(
            minimumShift: 1,
            maximumShiftRatio: 0.75,
            sampleStride: 1,
            acceptanceScore: 2
        )
        let stitcher = ScrollStitcher(matcher: matcher, maximumHeight: 14)

        _ = stitcher.append(first)
        XCTAssertEqual(stitcher.append(second), .reachedMaximum(totalHeight: 12))
        XCTAssertEqual(try XCTUnwrap(stitcher.makeImage()).height, 12)
    }
}
