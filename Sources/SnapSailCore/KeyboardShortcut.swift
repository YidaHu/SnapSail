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

public enum ShortcutKeyLabel {
    public static func label(keyCode: UInt16, characters: String?) -> String? {
        let specialKeys: [UInt16: String] = [
            36: "Return", 48: "Tab", 49: "Space", 51: "Delete", 53: "Esc",
            64: "F17", 79: "F18", 80: "F19", 90: "F20", 96: "F5", 97: "F6",
            98: "F7", 99: "F3", 100: "F8", 101: "F9", 103: "F11", 105: "F13",
            106: "F16", 107: "F14", 109: "F10", 111: "F12", 113: "F15",
            115: "Home", 116: "Page Up", 117: "Forward Delete", 118: "F4", 119: "End",
            120: "F2", 121: "Page Down", 122: "F1", 123: "←", 124: "→", 125: "↓", 126: "↑"
        ]
        if let special = specialKeys[keyCode] { return special }

        let modifierKeyCodes: Set<UInt16> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
        guard !modifierKeyCodes.contains(keyCode), let characters, !characters.isEmpty else { return nil }
        return characters.uppercased()
    }
}
