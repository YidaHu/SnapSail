import XCTest
@testable import SnapSailCore

final class PinInteractionTests: XCTestCase {
    func testSinglePrimaryClickStartsWindowDrag() {
        XCTAssertEqual(PinInteraction.primaryAction(clickCount: 1), .drag)
    }

    func testDoublePrimaryClickClosesWindow() {
        XCTAssertEqual(PinInteraction.primaryAction(clickCount: 2), .close)
    }
}
