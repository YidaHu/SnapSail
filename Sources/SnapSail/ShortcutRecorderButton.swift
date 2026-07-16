import AppKit
import SnapSailCore

final class ShortcutRecorderButton: NSButton {
    let shortcutAction: CaptureShortcutAction
    var onShortcutProposed: ((KeyboardShortcut) -> Bool)?

    private var shortcut: KeyboardShortcut
    private var isRecording = false

    init(action: CaptureShortcutAction, shortcut: KeyboardShortcut) {
        shortcutAction = action
        self.shortcut = shortcut
        super.init(frame: .zero)
        bezelStyle = .rounded
        focusRingType = .none
        font = .monospacedSystemFont(ofSize: 12, weight: .semibold)
        toolTip = "Click, then press a shortcut. Delete restores the default."
        setAccessibilityLabel("\(action.accessibilityTitle) shortcut")
        updateTitle()
    }

    required init?(coder: NSCoder) { nil }

    override var acceptsFirstResponder: Bool { true }

    func setShortcut(_ shortcut: KeyboardShortcut) {
        self.shortcut = shortcut
        guard !isRecording else { return }
        updateTitle()
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        isRecording = true
        title = "Press shortcut…"
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        if event.keyCode == 53 {
            stopRecording()
            return
        }
        if event.keyCode == 51 || event.keyCode == 117 {
            propose(shortcutAction.defaultShortcut)
            return
        }

        let modifiers = shortcutModifiers(from: event.modifierFlags)
        guard !modifiers.isEmpty,
              let keyDisplay = ShortcutKeyLabel.label(
                keyCode: event.keyCode,
                characters: event.charactersIgnoringModifiers
              ) else {
            NSSound.beep()
            title = "Add a modifier"
            return
        }
        propose(KeyboardShortcut(
            keyCode: UInt32(event.keyCode),
            modifiers: modifiers,
            keyDisplay: keyDisplay
        ))
    }

    override func flagsChanged(with event: NSEvent) {
        guard isRecording else {
            super.flagsChanged(with: event)
            return
        }
        let modifiers = shortcutModifiers(from: event.modifierFlags)
        let preview = KeyboardShortcut(keyCode: 0, modifiers: modifiers, keyDisplay: "…")
        title = modifiers.isEmpty ? "Press shortcut…" : preview.displayString
    }

    override func resignFirstResponder() -> Bool {
        stopRecording()
        return super.resignFirstResponder()
    }

    private func propose(_ candidate: KeyboardShortcut) {
        guard onShortcutProposed?(candidate) == true else {
            NSSound.beep()
            stopRecording()
            return
        }
        shortcut = candidate
        stopRecording()
    }

    private func stopRecording() {
        isRecording = false
        updateTitle()
    }

    private func updateTitle() {
        title = shortcut.displayString
    }

    private func shortcutModifiers(from flags: NSEvent.ModifierFlags) -> ShortcutModifiers {
        var modifiers: ShortcutModifiers = []
        let deviceIndependent = flags.intersection(.deviceIndependentFlagsMask)
        if deviceIndependent.contains(.command) { modifiers.insert(.command) }
        if deviceIndependent.contains(.shift) { modifiers.insert(.shift) }
        if deviceIndependent.contains(.option) { modifiers.insert(.option) }
        if deviceIndependent.contains(.control) { modifiers.insert(.control) }
        return modifiers
    }
}

private extension CaptureShortcutAction {
    var accessibilityTitle: String {
        switch self {
        case .area: return "Capture Area"
        case .window: return "Capture Window"
        case .scrolling: return "Scrolling Capture"
        }
    }
}
