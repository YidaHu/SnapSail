import CoreGraphics
import XCTest
@testable import SnapSailCore

final class CaptureGeometryTests: XCTestCase {
    func testConvertsGlobalBottomLeftRectToDisplayLocalTopLeftRect() {
        let display = CGRect(x: 1440, y: -200, width: 1920, height: 1080)
        let selection = CGRect(x: 1540, y: 600, width: 500, height: 200)

        let result = CaptureGeometry.sourceRect(
            globalSelection: selection,
            displayFrame: display
        )

        XCTAssertEqual(result, CGRect(x: 100, y: 80, width: 500, height: 200))
    }

    func testClampsSelectionToDisplayBounds() {
        let display = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let selection = CGRect(x: -20, y: 700, width: 200, height: 200)

        let result = CaptureGeometry.sourceRect(
            globalSelection: selection,
            displayFrame: display
        )

        XCTAssertEqual(result, CGRect(x: 0, y: 0, width: 180, height: 100))
    }

    func testConvertsBetweenAppKitAndQuartzGlobalCoordinates() {
        let primaryHeight: CGFloat = 900
        let appKitRect = CGRect(x: 120, y: 100, width: 400, height: 250)

        let quartzRect = CaptureGeometry.quartzRect(
            fromAppKitRect: appKitRect,
            primaryScreenHeight: primaryHeight
        )

        XCTAssertEqual(quartzRect, CGRect(x: 120, y: 550, width: 400, height: 250))
        XCTAssertEqual(
            CaptureGeometry.appKitRect(
                fromQuartzRect: quartzRect,
                primaryScreenHeight: primaryHeight
            ),
            appKitRect
        )
    }
}
