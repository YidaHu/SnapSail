import Foundation
import XCTest

final class SelectionOverlaySafetyTests: XCTestCase {
    func testAreaCaptureFreezesPixelsBeforeActivatingSelectionOverlay() throws {
        let sourceURL = projectRoot
            .appendingPathComponent("Sources/SnapSail/CaptureCoordinator.swift")
        let source = try String(contentsOf: sourceURL)
        let methodStart = try XCTUnwrap(source.range(of: "private func beginAreaCapture(scrolling: Bool)"))
        let methodEnd = try XCTUnwrap(
            source.range(of: "private func beginWindowCapture()", range: methodStart.upperBound..<source.endIndex)
        )
        let methodBody = String(source[methodStart.lowerBound..<methodEnd.lowerBound])

        let freeze = try XCTUnwrap(methodBody.range(of: "captureService.freezeDesktop()"))
        let overlay = try XCTUnwrap(methodBody.range(of: "SelectionOverlayController("))
        XCTAssertLessThan(
            freeze.lowerBound,
            overlay.lowerBound,
            "Visible pixels must be frozen before the overlay activates SnapSail and dismisses transient popups."
        )
        XCTAssertTrue(
            methodBody.contains("frozenDesktop.image(in: rect)"),
            "The final area screenshot must come from the pre-activation frozen pixels."
        )
        XCTAssertFalse(
            methodBody.contains("captureService.capture(appKitRect: rect)"),
            "Area capture must not re-read the live screen after a focus-sensitive popup has closed."
        )
    }

    func testAreaSelectionRevealRestoresFrozenPixelsAfterClearingDimLayer() throws {
        let sourceURL = projectRoot
            .appendingPathComponent("Sources/SnapSail/SelectionOverlay.swift")
        let source = try String(contentsOf: sourceURL)
        let drawStart = try XCTUnwrap(source.range(of: "override func draw(_ dirtyRect: NSRect)"))
        let mouseDownStart = try XCTUnwrap(
            source.range(of: "override func mouseDown(with event: NSEvent)", range: drawStart.upperBound..<source.endIndex)
        )
        let drawBody = String(source[drawStart.lowerBound..<mouseDownStart.lowerBound])
        let clear = try XCTUnwrap(drawBody.range(of: "region.fill(using: .copy)"))
        let restore = try XCTUnwrap(drawBody.range(of: "drawFrozenBackground(in: region)"))

        XCTAssertLessThan(
            clear.lowerBound,
            restore.lowerBound,
            "Clearing the dim layer must be followed by restoring frozen pixels inside the selection."
        )
    }

    func testCaptureEntryPointsIgnoreReentrantOverlayRequests() throws {
        let sourceURL = projectRoot
            .appendingPathComponent("Sources/SnapSail/CaptureCoordinator.swift")
        let source = try String(contentsOf: sourceURL)

        for (method, nextMethod) in [
            ("private func beginAreaCapture(scrolling: Bool)", "private func beginWindowCapture()"),
            ("private func beginWindowCapture()", "private func startScrolling(rect: CGRect)")
        ] {
            let methodStart = try XCTUnwrap(source.range(of: method))
            let methodEnd = try XCTUnwrap(
                source.range(of: nextMethod, range: methodStart.upperBound..<source.endIndex)
            )
            let methodBody = String(source[methodStart.lowerBound..<methodEnd.lowerBound])

            XCTAssertTrue(
                methodBody.contains("guard selectionOverlay == nil else { return }"),
                "\(method) must not replace a live full-screen overlay with an unreachable one."
            )
        }
    }

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
