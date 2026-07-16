import XCTest
@testable import SnapSailCore

final class KeyboardShortcutTests: XCTestCase {
    func testCaptureActionsProvideExpectedDefaults() {
        XCTAssertEqual(
            CaptureShortcutAction.area.defaultShortcut,
            KeyboardShortcut(keyCode: 19, modifiers: [.command, .shift], keyDisplay: "2")
        )
        XCTAssertEqual(CaptureShortcutAction.window.defaultShortcut.keyDisplay, "3")
        XCTAssertEqual(CaptureShortcutAction.scrolling.defaultShortcut.keyDisplay, "4")
    }

    func testDisplayStringUsesMacModifierOrder() {
        let shortcut = KeyboardShortcut(
            keyCode: 15,
            modifiers: [.command, .shift, .option, .control],
            keyDisplay: "R"
        )

        XCTAssertEqual(shortcut.displayString, "⌘ ⇧ ⌥ ⌃ R")
    }

    func testConflictIgnoresCurrentActionButFindsOtherActions() {
        let shortcuts = Dictionary(uniqueKeysWithValues: CaptureShortcutAction.allCases.map {
            ($0, $0.defaultShortcut)
        })

        XCTAssertFalse(CaptureShortcutAction.area.defaultShortcut.conflicts(for: .area, among: shortcuts))
        XCTAssertTrue(CaptureShortcutAction.area.defaultShortcut.conflicts(for: .window, among: shortcuts))
    }

    func testKeyLabelsCoverOrdinaryAndSpecialKeys() {
        XCTAssertEqual(ShortcutKeyLabel.label(keyCode: 15, characters: "r"), "R")
        XCTAssertEqual(ShortcutKeyLabel.label(keyCode: 49, characters: " "), "Space")
        XCTAssertEqual(ShortcutKeyLabel.label(keyCode: 122, characters: nil), "F1")
        XCTAssertNil(ShortcutKeyLabel.label(keyCode: 55, characters: nil))
    }

    func testFunctionKeysCanBeUsedWithoutModifiers() {
        let f1 = KeyboardShortcut(keyCode: 122, modifiers: [], keyDisplay: "F1")
        let letter = KeyboardShortcut(keyCode: 0, modifiers: [], keyDisplay: "A")

        XCTAssertTrue(f1.isValidGlobalShortcut)
        XCTAssertFalse(letter.isValidGlobalShortcut)
        XCTAssertEqual(f1.menuKeyEquivalent, String(UnicodeScalar(0xF704)!))
    }
}
