import XCTest

final class BuildScriptTests: XCTestCase {
    func testReleaseAppUsesPersistentCodeSigningIdentity() throws {
        let testFile = URL(fileURLWithPath: #filePath)
        let projectRoot = testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let scriptURL = projectRoot.appendingPathComponent("Scripts/build-app.sh")
        let script = try String(contentsOf: scriptURL)

        XCTAssertFalse(
            script.contains("codesign --force --deep --sign -"),
            "Ad-hoc signatures change the designated requirement after every build, so macOS forgets Screen Recording permission."
        )
        XCTAssertTrue(
            script.contains("SNAPSAIL_CODESIGN_IDENTITY"),
            "The release script must use a persistent signing identity."
        )
    }
}
