import CoreGraphics
import XCTest
@testable import SnapSailCore

final class SelectionModelTests: XCTestCase {
    func testMoveClampsSelectionInsideBounds() {
        var model = SelectionModel(bounds: CGRect(x: 0, y: 0, width: 500, height: 400))
        model.setRegion(CGRect(x: 100, y: 100, width: 200, height: 120))
        model.move(by: CGSize(width: 300, height: 300))
        XCTAssertEqual(model.region, CGRect(x: 300, y: 280, width: 200, height: 120))
    }

    func testResizeFromTopLeftKeepsMinimumSize() {
        var model = SelectionModel(bounds: CGRect(x: 0, y: 0, width: 500, height: 400))
        model.setRegion(CGRect(x: 100, y: 100, width: 200, height: 120))
        model.resize(handle: .topLeft, to: CGPoint(x: 295, y: 215))
        XCTAssertEqual(model.region, CGRect(x: 276, y: 100, width: 24, height: 115))
    }

    func testKeyboardNudgeUsesOneOrTenPoints() {
        var model = SelectionModel(bounds: CGRect(x: 0, y: 0, width: 500, height: 400))
        model.setRegion(CGRect(x: 100, y: 100, width: 200, height: 120))
        model.nudge(dx: 1, dy: 0, accelerated: false)
        model.nudge(dx: 0, dy: 1, accelerated: true)
        XCTAssertEqual(model.region?.origin, CGPoint(x: 101, y: 110))
    }

    func testFindsCornerAndEdgeHandles() {
        var model = SelectionModel(bounds: CGRect(x: 0, y: 0, width: 500, height: 400))
        model.setRegion(CGRect(x: 100, y: 100, width: 200, height: 120))
        XCTAssertEqual(model.handle(at: CGPoint(x: 100, y: 220), tolerance: 8), .topLeft)
        XCTAssertEqual(model.handle(at: CGPoint(x: 200, y: 100), tolerance: 8), .bottom)
        XCTAssertNil(model.handle(at: CGPoint(x: 200, y: 160), tolerance: 8))
    }
}
