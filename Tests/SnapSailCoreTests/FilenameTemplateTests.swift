import XCTest
@testable import SnapSailCore

final class FilenameTemplateTests: XCTestCase {
    func testBuildsStableTimestampedFilename() {
        let date = Date(timeIntervalSince1970: 1_718_433_445)
        let timezone = TimeZone(secondsFromGMT: 8 * 3_600)!

        let result = FilenameTemplate.filename(
            prefix: "SnapSail",
            date: date,
            fileExtension: "png",
            timeZone: timezone
        )

        XCTAssertEqual(result, "SnapSail-2024-06-15-14-37-25.png")
    }

    func testSanitizesPrefixForFilesystemUse() {
        let date = Date(timeIntervalSince1970: 0)
        let timezone = TimeZone(secondsFromGMT: 0)!

        let result = FilenameTemplate.filename(
            prefix: "Product / Review",
            date: date,
            fileExtension: "jpg",
            timeZone: timezone
        )

        XCTAssertEqual(result, "Product-Review-1970-01-01-00-00-00.jpg")
    }
}
