import AppKit
import Foundation
import SnapSailCore

enum CaptureOutputFormat: String, CaseIterable {
    case png
    case jpeg

    var fileExtension: String { self == .png ? "png" : "jpg" }
}

final class AppPreferences {
    static let shared = AppPreferences()

    private enum Key {
        static let outputFormat = "outputFormat"
        static let jpegQuality = "jpegQuality"
        static let includeWindowShadow = "includeWindowShadow"
        static let playSound = "playSound"
        static let showNotification = "showNotification"
        static let copyAfterCapture = "copyAfterCapture"
        static let saveAfterCapture = "saveAfterCapture"
        static let saveDirectory = "saveDirectory"
        static let filenamePrefix = "filenamePrefix"
        static let historyEnabled = "historyEnabled"
        static let language = "language"

        static func shortcutKeyCode(_ action: CaptureShortcutAction) -> String {
            "shortcut.\(action.rawValue).keyCode"
        }

        static func shortcutModifiers(_ action: CaptureShortcutAction) -> String {
            "shortcut.\(action.rawValue).modifiers"
        }

        static func shortcutDisplay(_ action: CaptureShortcutAction) -> String {
            "shortcut.\(action.rawValue).display"
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        var registeredValues: [String: Any] = [
            Key.outputFormat: CaptureOutputFormat.png.rawValue,
            Key.jpegQuality: 0.9,
            Key.includeWindowShadow: true,
            Key.playSound: true,
            Key.showNotification: true,
            Key.copyAfterCapture: false,
            Key.saveAfterCapture: false,
            Key.saveDirectory: FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? NSHomeDirectory(),
            Key.filenamePrefix: "SnapSail",
            Key.historyEnabled: true,
            Key.language: AppLanguage.english.rawValue
        ]
        for action in CaptureShortcutAction.allCases {
            let shortcut = action.defaultShortcut
            registeredValues[Key.shortcutKeyCode(action)] = Int(shortcut.keyCode)
            registeredValues[Key.shortcutModifiers(action)] = Int(shortcut.modifiers.rawValue)
            registeredValues[Key.shortcutDisplay(action)] = shortcut.keyDisplay
        }
        defaults.register(defaults: registeredValues)
    }

    var outputFormat: CaptureOutputFormat {
        get { CaptureOutputFormat(rawValue: defaults.string(forKey: Key.outputFormat) ?? "png") ?? .png }
        set { defaults.set(newValue.rawValue, forKey: Key.outputFormat) }
    }

    var jpegQuality: Double {
        get { defaults.double(forKey: Key.jpegQuality) }
        set { defaults.set(max(0.1, min(1, newValue)), forKey: Key.jpegQuality) }
    }

    var includeWindowShadow: Bool {
        get { defaults.bool(forKey: Key.includeWindowShadow) }
        set { defaults.set(newValue, forKey: Key.includeWindowShadow) }
    }

    var playSound: Bool {
        get { defaults.bool(forKey: Key.playSound) }
        set { defaults.set(newValue, forKey: Key.playSound) }
    }

    var showNotification: Bool {
        get { defaults.bool(forKey: Key.showNotification) }
        set { defaults.set(newValue, forKey: Key.showNotification) }
    }

    var copyAfterCapture: Bool {
        get { defaults.bool(forKey: Key.copyAfterCapture) }
        set { defaults.set(newValue, forKey: Key.copyAfterCapture) }
    }

    var saveAfterCapture: Bool {
        get { defaults.bool(forKey: Key.saveAfterCapture) }
        set { defaults.set(newValue, forKey: Key.saveAfterCapture) }
    }

    var saveDirectory: URL {
        get { URL(fileURLWithPath: defaults.string(forKey: Key.saveDirectory) ?? NSHomeDirectory(), isDirectory: true) }
        set { defaults.set(newValue.path, forKey: Key.saveDirectory) }
    }

    var filenamePrefix: String {
        get { defaults.string(forKey: Key.filenamePrefix) ?? "SnapSail" }
        set { defaults.set(newValue, forKey: Key.filenamePrefix) }
    }

    var historyEnabled: Bool {
        get { defaults.bool(forKey: Key.historyEnabled) }
        set { defaults.set(newValue, forKey: Key.historyEnabled) }
    }

    var language: AppLanguage {
        get { AppLanguage(rawValue: defaults.string(forKey: Key.language) ?? "english") ?? .english }
        set { defaults.set(newValue.rawValue, forKey: Key.language) }
    }

    func shortcut(for action: CaptureShortcutAction) -> KeyboardShortcut {
        KeyboardShortcut(
            keyCode: UInt32(defaults.integer(forKey: Key.shortcutKeyCode(action))),
            modifiers: ShortcutModifiers(
                rawValue: UInt(defaults.integer(forKey: Key.shortcutModifiers(action)))
            ),
            keyDisplay: defaults.string(forKey: Key.shortcutDisplay(action))
                ?? action.defaultShortcut.keyDisplay
        )
    }

    func setShortcut(_ shortcut: KeyboardShortcut, for action: CaptureShortcutAction) {
        defaults.set(Int(shortcut.keyCode), forKey: Key.shortcutKeyCode(action))
        defaults.set(Int(shortcut.modifiers.rawValue), forKey: Key.shortcutModifiers(action))
        defaults.set(shortcut.keyDisplay, forKey: Key.shortcutDisplay(action))
    }

    func resetShortcut(for action: CaptureShortcutAction) {
        setShortcut(action.defaultShortcut, for: action)
    }

    var shortcuts: [CaptureShortcutAction: KeyboardShortcut] {
        Dictionary(uniqueKeysWithValues: CaptureShortcutAction.allCases.map {
            ($0, shortcut(for: $0))
        })
    }
}
