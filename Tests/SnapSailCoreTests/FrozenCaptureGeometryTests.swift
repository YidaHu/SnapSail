import CoreGraphics
import XCTest
@testable import SnapSailCore

final class FrozenCaptureGeometryTests: XCTestCase {
    func testMapsAppKitSelectionToRetinaImagePixels() throws {
        let crop = try XCTUnwrap(FrozenCaptureGeometry.pixelCropRect(
            appKitRect: CGRect(x: 10, y: 20, width: 30, height: 40),
            screenFrame: CGRect(x: 0, y: 0, width: 100, height: 100),
            imagePixelSize: CGSize(width: 200, height: 200)
        ))

        XCTAssertEqual(crop, CGRect(x: 20, y: 80, width: 60, height: 80))
    }

    func testMapsSelectionOnNegativeOriginSecondaryDisplay() throws {
        let crop = try XCTUnwrap(FrozenCaptureGeometry.pixelCropRect(
            appKitRect: CGRect(x: -900, y: -50, width: 200, height: 100),
            screenFrame: CGRect(x: -1000, y: -100, width: 1000, height: 800),
            imagePixelSize: CGSize(width: 2000, height: 1600)
        ))

        XCTAssertEqual(crop, CGRect(x: 200, y: 1300, width: 400, height: 200))
    }

    func testClipsSelectionToCapturedScreenBounds() throws {
        let crop = try XCTUnwrap(FrozenCaptureGeometry.pixelCropRect(
            appKitRect: CGRect(x: 90, y: 90, width: 20, height: 20),
            screenFrame: CGRect(x: 0, y: 0, width: 100, height: 100),
            imagePixelSize: CGSize(width: 200, height: 200)
        ))

        XCTAssertEqual(crop, CGRect(x: 180, y: 0, width: 20, height: 20))
    }

    func testRejectsSelectionOutsideCapturedScreen() {
        XCTAssertNil(FrozenCaptureGeometry.pixelCropRect(
            appKitRect: CGRect(x: 200, y: 200, width: 20, height: 20),
            screenFrame: CGRect(x: 0, y: 0, width: 100, height: 100),
            imagePixelSize: CGSize(width: 200, height: 200)
        ))
    }
}
