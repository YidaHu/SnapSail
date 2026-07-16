import XCTest
@testable import SnapSailCore

final class AppLocalizationTests: XCTestCase {
    func testReturnsEnglishAndSimplifiedChineseText() {
        XCTAssertEqual(AppLocalization.text(.captureArea, language: .english), "Capture Area")
        XCTAssertEqual(AppLocalization.text(.captureArea, language: .simplifiedChinese), "区域截图")
        XCTAssertEqual(AppLanguage.simplifiedChinese.displayName, "简体中文")
    }

    func testEveryKeyHasCompleteNonEmptyTranslations() {
        for language in AppLanguage.allCases {
            for key in AppTextKey.allCases {
                XCTAssertTrue(
                    AppLocalization.hasTranslation(key, language: language),
                    "Missing \(language.rawValue) translation for \(key.rawValue)"
                )
                XCTAssertFalse(AppLocalization.text(key, language: language).isEmpty)
            }
        }
    }
}
