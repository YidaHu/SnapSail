import Foundation
import XCTest

final class SelectionOverlaySafetyTests: XCTestCase {
    func testSubminimumSelectionCancelsOverlayInsteadOfLeavingInputBlocked() throws {
        let sourceURL = projectRoot
            .appendingPathComponent("Sources/SnapSail/SelectionOverlay.swift")
        let source = try String(contentsOf: sourceURL)
        let mouseUpStart = try XCTUnwrap(source.range(of: "override func mouseUp(with event: NSEvent)"))
        let mouseMovedStart = try XCTUnwrap(
            source.range(of: "override func mouseMoved(with event: NSEvent)", range: mouseUpStart.upperBound..<source.endIndex)
        )
        let mouseUpBody = String(source[mouseUpStart.lowerBound..<mouseMovedStart.lowerBound])

        XCTAssertTrue(
            mouseUpBody.contains("region.width >= selection.minimumSize")
                && mouseUpBody.contains("region.height >= selection.minimumSize"),
            "Selection validation must use the model's minimum size instead of a duplicated literal."
        )
        XCTAssertTrue(
            mouseUpBody.contains("controller?.cancel()"),
            "A tiny selection must close every full-screen overlay instead of hiding controls while blocking input."
        )
    }

    private var projectRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
