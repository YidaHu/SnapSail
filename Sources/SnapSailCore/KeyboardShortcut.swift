import Foundation

public struct ShortcutModifiers: OptionSet, Hashable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let command = ShortcutModifiers(rawValue: 1 << 0)
    public static let shift = ShortcutModifiers(rawValue: 1 << 1)
    public static let option = ShortcutModifiers(rawValue: 1 << 2)
    public static let control = ShortcutModifiers(rawValue: 1 << 3)
}

public struct KeyboardShortcut: Equatable, Hashable {
    public let keyCode: UInt32
    public let modifiers: ShortcutModifiers
    public let keyDisplay: String

    public init(keyCode: UInt32, modifiers: ShortcutModifiers, keyDisplay: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.keyDisplay = keyDisplay
    }

    public var displayString: String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        parts.append(keyDisplay)
        return parts.joined(separator: " ")
    }

    public func conflicts(
        for action: CaptureShortcutAction,
        among shortcuts: [CaptureShortcutAction: KeyboardShortcut]
    ) -> Bool {
        shortcuts.contains { candidateAction, shortcut in
            candidateAction != action && shortcut == self
        }
    }
}

public enum CaptureShortcutAction: String, CaseIterable, Hashable {
    case area
    case window
    case scrolling

    public var registrationID: UInt32 {
        switch self {
        case .area: return 2
        case .window: return 3
        case .scrolling: return 4
        }
    }

    public var defaultShortcut: KeyboardShortcut {
        let keyCode: UInt32
        let keyDisplay: String
        switch self {
        case .area:
            keyCode = 19
            keyDisplay = "2"
        case .window:
            keyCode = 20
            keyDisplay = "3"
        case .scrolling:
            keyCode = 21
            keyDisplay = "4"
        }
        return KeyboardShortcut(
            keyCode: keyCode,
            modifiers: [.command, .shift],
            keyDisplay: keyDisplay
        )
    }
}
