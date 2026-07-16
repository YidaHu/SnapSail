import CoreGraphics
import XCTest
@testable import SnapSailCore

final class OverlayScreenGeometryTests: XCTestCase {
    func testUsesScreenLocalOriginForMainDisplay() {
        let frame = CGRect(x: 0, y: 0, width: 1680, height: 1050)
        XCTAssertEqual(
            OverlayScreenGeometry.localContentRect(for: frame),
            CGRect(x: 0, y: 0, width: 1680, height: 1050)
        )
    }

    func testDoesNotRepeatNegativeSecondaryDisplayOrigin() {
        let frame = CGRect(x: -1080, y: -8, width: 1080, height: 1920)
        XCTAssertEqual(
            OverlayScreenGeometry.localContentRect(for: frame),
            CGRect(x: 0, y: 0, width: 1080, height: 1920)
        )
    }

    func testDoesNotRepeatUpperDisplayOrigin() {
        let frame = CGRect(x: 0, y: 1050, width: 1920, height: 1080)
        XCTAssertEqual(
            OverlayScreenGeometry.localContentRect(for: frame),
            CGRect(x: 0, y: 0, width: 1920, height: 1080)
        )
    }
}
