import AppKit
import SnapSailCore
import XCTest
@testable import SnapSail

final class InlineCaptureToolbarTests: XCTestCase {
    func testUsesProductPageContainerMetrics() {
        let toolbar = makeToolbar()

        XCTAssertEqual(InlineCaptureToolbar.preferredSize, CGSize(width: 744, height: 62))
        XCTAssertEqual(toolbar.layer?.cornerRadius, 22)
    }

    func testSpacesAnnotationButtonsWithFourPointGap() throws {
        let toolbar = makeToolbar()
        let rectangle = try button(tag: InlineAnnotationTool.rectangle.rawValue, in: toolbar)
        let ellipse = try button(tag: InlineAnnotationTool.ellipse.rawValue, in: toolbar)

        XCTAssertEqual(ellipse.frame.minX - rectangle.frame.maxX, 4)
        XCTAssertEqual(rectangle.frame.size, CGSize(width: 40, height: 42))
    }

    func testUsesPaleBlueSelectionAndSolidBlueCompletion() throws {
        let toolbar = makeToolbar()
        let rectangle = try button(identifier: "capture.tool.rectangle", in: toolbar)
        let copy = try button(identifier: "capture.copy", in: toolbar)

        rectangle.performClick(nil)

        let expectedSelectionColor = NSColor(
            calibratedRed: 0.906,
            green: 0.945,
            blue: 1,
            alpha: 1
        )
        assertColor(rectangle.layer?.backgroundColor, equals: expectedSelectionColor.cgColor)
        XCTAssertEqual(rectangle.contentTintColor, SnapSailStyle.accent)
        assertColor(copy.layer?.backgroundColor, equals: SnapSailStyle.accent.cgColor)
        XCTAssertEqual(copy.contentTintColor, .white)
    }

    func testKeepsAllExistingToolbarActionsDiscoverable() throws {
        let toolbar = makeToolbar()
        let identifiers = [
            "capture.color", "capture.undo", "capture.redo", "capture.cancel",
            "capture.scroll", "capture.save", "capture.copy"
        ]

        for identifier in identifiers {
            _ = try button(identifier: identifier, in: toolbar)
        }
        XCTAssertEqual(toolbar.subviews.compactMap { $0 as? NSButton }.count, 16)
    }

    private func makeToolbar() -> InlineCaptureToolbar {
        InlineCaptureToolbar(frame: CGRect(origin: .zero, size: InlineCaptureToolbar.preferredSize))
    }

    private func button(identifier: String, in toolbar: InlineCaptureToolbar) throws -> NSButton {
        try XCTUnwrap(toolbar.subviews.compactMap { $0 as? NSButton }.first {
            $0.identifier?.rawValue == identifier
        })
    }

    private func button(tag: Int, in toolbar: InlineCaptureToolbar) throws -> NSButton {
        try XCTUnwrap(toolbar.subviews.compactMap { $0 as? NSButton }.first { $0.tag == tag })
    }

    private func assertColor(
        _ actual: CGColor?,
        equals expected: CGColor,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let actual else {
            XCTFail("Expected a layer background color", file: file, line: line)
            return
        }
        XCTAssertTrue(actual == expected, "Expected \(expected), received \(actual)", file: file, line: line)
    }
}
