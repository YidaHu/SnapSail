import AppKit
import XCTest
@testable import SnapSail

final class MeasurementPillViewTests: XCTestCase {
    func testUsesCompactProductPageInspiredMetrics() throws {
        let pill = MeasurementPillView(frame: CGRect(x: 0, y: 0, width: 164, height: 34))
        pill.layoutSubtreeIfNeeded()

        XCTAssertEqual(pill.intrinsicContentSize, CGSize(width: 164, height: 34))
        XCTAssertEqual(pill.layer?.cornerRadius, 6)

        let labels = pill.subviews.compactMap { $0 as? NSTextField }
        let numericLabels = labels.filter { $0.stringValue == "0" }
        let unitLabel = try XCTUnwrap(labels.first { $0.stringValue == "pt" })
        XCTAssertEqual(numericLabels.count, 2)
        XCTAssertTrue(numericLabels.allSatisfy { $0.font?.pointSize == 14 })
        XCTAssertEqual(unitLabel.font?.pointSize, 10)

        let lockView = try XCTUnwrap(pill.subviews.compactMap { $0 as? NSImageView }.first)
        let expectedLock = try XCTUnwrap(SnapSailStyle.symbol("lock.fill", size: 10, weight: .semibold))
        XCTAssertEqual(lockView.image?.tiffRepresentation, expectedLock.tiffRepresentation)
    }
}
