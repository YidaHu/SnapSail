import XCTest

final class CaptureCompletionBehaviorTests: XCTestCase {
    func testCopyAndDownloadButtonsHaveIndependentOutputEffects() throws {
        let source = try captureCoordinatorSource()
        let copyBlock = try XCTUnwrap(source.range(
            of: "case .copy, .scroll:\n            recordAndCopy(image)"
        ))
        let saveBlockStart = try XCTUnwrap(source.range(of: "case .save:", range: copyBlock.upperBound..<source.endIndex))
        let saveBlockEnd = try XCTUnwrap(source.range(of: "case .pin:", range: saveBlockStart.upperBound..<source.endIndex))
        let saveBlock = String(source[saveBlockStart.lowerBound..<saveBlockEnd.lowerBound])

        XCTAssertTrue(saveBlock.contains("ImageExporter.save(image, to: preferences.saveDirectory"))
        XCTAssertFalse(saveBlock.contains("presentSavePanel"))
        XCTAssertFalse(saveBlock.contains("recordAndCopy"), "Downloading must not also overwrite the clipboard.")
    }

    func testCopyButtonDoesNotHonorAutomaticFileSavingPreference() throws {
        let source = try captureCoordinatorSource()
        let copyBlockStart = try XCTUnwrap(source.range(of: "case .copy, .scroll:"))
        let copyBlockEnd = try XCTUnwrap(source.range(of: "case .save:", range: copyBlockStart.upperBound..<source.endIndex))
        let copyBlock = String(source[copyBlockStart.lowerBound..<copyBlockEnd.lowerBound])

        XCTAssertTrue(copyBlock.contains("recordAndCopy(image)"))
        XCTAssertFalse(copyBlock.contains("saveAfterCapture"))
        XCTAssertFalse(copyBlock.contains("ImageExporter.save"))
    }

    private func captureCoordinatorSource() throws -> String {
        let testFile = URL(fileURLWithPath: #filePath)
        let projectRoot = testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(contentsOf: projectRoot.appendingPathComponent("Sources/SnapSail/CaptureCoordinator.swift"))
    }
}
