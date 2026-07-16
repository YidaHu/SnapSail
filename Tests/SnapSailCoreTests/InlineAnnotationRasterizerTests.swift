import CoreGraphics
import XCTest
@testable import SnapSailCore

final class InlineAnnotationRasterizerTests: XCTestCase {
    func testRenderingPreservesBasePixelDimensions() throws {
        let base = TestImageFactory.patternedImage(width: 100, rows: 0..<50)
        let annotation = InlineAnnotation(
            tool: .rectangle,
            start: CGPoint(x: 0.1, y: 0.1),
            end: CGPoint(x: 0.9, y: 0.9),
            lineWidth: 3
        )

        let rendered = try XCTUnwrap(InlineAnnotationRasterizer.render(
            base: base,
            annotations: [annotation],
            selectionPointSize: CGSize(width: 50, height: 25)
        ))

        XCTAssertEqual(rendered.width, 100)
        XCTAssertEqual(rendered.height, 50)
        XCTAssertNotEqual(TestImageFactory.rgba(rendered), TestImageFactory.rgba(base))
    }
}
