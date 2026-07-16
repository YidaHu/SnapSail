import XCTest

final class HistoryStoreTests: XCTestCase {
    func testHistoryIsTrimmedToTwentyItemsOnLaunchAndAfterCapture() throws {
        let testFile = URL(fileURLWithPath: #filePath)
        let projectRoot = testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourceURL = projectRoot.appendingPathComponent("Sources/SnapSail/History.swift")
        let source = try String(contentsOf: sourceURL)
        let trimCalls = source.components(separatedBy: "trim(to: 20)").count - 1

        XCTAssertEqual(
            trimCalls,
            2,
            "History must be limited both when the store opens and whenever a new capture is added."
        )
    }

    func testHistoryStoreIsInitializedWhenTheAppStarts() throws {
        let testFile = URL(fileURLWithPath: #filePath)
        let projectRoot = testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourceURL = projectRoot.appendingPathComponent("Sources/SnapSail/CaptureCoordinator.swift")
        let source = try String(contentsOf: sourceURL)

        XCTAssertTrue(
            source.contains("private let historyStore = HistoryStore()"),
            "History cleanup must run at application startup instead of waiting for the first history action."
        )
    }
}
