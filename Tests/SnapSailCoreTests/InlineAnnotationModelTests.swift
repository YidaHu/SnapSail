import CoreGraphics
import XCTest
@testable import SnapSailCore

final class InlineAnnotationModelTests: XCTestCase {
    func testCommitUndoAndRedoPreserveAnnotationOrder() {
        var history = InlineAnnotationHistory()
        let rectangle = InlineAnnotation(
            tool: .rectangle,
            start: CGPoint(x: 0.1, y: 0.2),
            end: CGPoint(x: 0.5, y: 0.7)
        )
        let arrow = InlineAnnotation(
            tool: .arrow,
            start: CGPoint(x: 0.2, y: 0.8),
            end: CGPoint(x: 0.9, y: 0.1)
        )

        history.commit(rectangle)
        history.commit(arrow)
        XCTAssertEqual(history.annotations, [rectangle, arrow])

        history.undo()
        XCTAssertEqual(history.annotations, [rectangle])
        XCTAssertTrue(history.canRedo)

        history.redo()
        XCTAssertEqual(history.annotations, [rectangle, arrow])
        XCTAssertFalse(history.canRedo)
    }

    func testNewCommitClearsRedoHistory() {
        var history = InlineAnnotationHistory()
        history.commit(InlineAnnotation(tool: .line, start: .zero, end: CGPoint(x: 1, y: 1)))
        history.undo()
        XCTAssertTrue(history.canRedo)

        history.commit(InlineAnnotation(tool: .ellipse, start: .zero, end: CGPoint(x: 0.5, y: 0.5)))
        XCTAssertFalse(history.canRedo)
        XCTAssertEqual(history.annotations.map(\.tool), [.ellipse])
    }

    func testNormalizesPointWithinSelectionBounds() {
        let selection = CGRect(x: 100, y: 50, width: 400, height: 200)
        XCTAssertEqual(
            InlineAnnotation.normalizedPoint(CGPoint(x: 300, y: 150), in: selection),
            CGPoint(x: 0.5, y: 0.5)
        )
        XCTAssertEqual(
            InlineAnnotation.normalizedPoint(CGPoint(x: 700, y: -50), in: selection),
            CGPoint(x: 1, y: 0)
        )
    }
}
