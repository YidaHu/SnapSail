import AppKit
import SnapSailCore

final class MenuBarController: NSObject {
    var onCaptureArea: (() -> Void)?
    var onCaptureWindow: (() -> Void)?
    var onScrollingCapture: (() -> Void)?
    var onHistory: (() -> Void)?
    var onSettings: (() -> Void)?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var captureItems: [CaptureShortcutAction: NSMenuItem] = [:]

    override init() {
        super.init()
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "SnapSail")
            button.toolTip = "SnapSail"
        }
        statusItem.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu(title: "SnapSail")
        let area = item(L10n.text(.captureArea), symbol: "viewfinder", action: #selector(captureArea), key: "2", modifiers: [.command, .shift])
        let window = item(L10n.text(.captureWindow), symbol: "macwindow", action: #selector(captureWindow), key: "3", modifiers: [.command, .shift])
        let scrolling = item(L10n.text(.scrollingCapture), symbol: "arrow.down.to.line.compact", action: #selector(scrollingCapture), key: "4", modifiers: [.command, .shift])
        captureItems[.area] = area
        captureItems[.window] = window
        captureItems[.scrolling] = scrolling
        menu.addItem(area)
        menu.addItem(window)
        menu.addItem(scrolling)
        menu.addItem(.separator())
        menu.addItem(item(L10n.text(.captureHistory), symbol: "clock.arrow.circlepath", action: #selector(showHistory), key: "h", modifiers: [.command]))
        menu.addItem(item(L10n.text(.settings), symbol: "gearshape", action: #selector(showSettings), key: ",", modifiers: [.command]))
        menu.addItem(.separator())

        let about = NSMenuItem(title: L10n.text(.about), action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(title: L10n.text(.quit), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
        return menu
    }

    func updateShortcuts(_ shortcuts: [CaptureShortcutAction: KeyboardShortcut]) {
        for (action, shortcut) in shortcuts {
            guard let item = captureItems[action] else { continue }
            item.keyEquivalent = shortcut.menuKeyEquivalent
            var flags: NSEvent.ModifierFlags = []
            if shortcut.modifiers.contains(.command) { flags.insert(.command) }
            if shortcut.modifiers.contains(.shift) { flags.insert(.shift) }
            if shortcut.modifiers.contains(.option) { flags.insert(.option) }
            if shortcut.modifiers.contains(.control) { flags.insert(.control) }
            item.keyEquivalentModifierMask = flags
        }
    }

    func updateLanguage(shortcuts: [CaptureShortcutAction: KeyboardShortcut]) {
        captureItems.removeAll()
        statusItem.menu = makeMenu()
        updateShortcuts(shortcuts)
    }

    private func item(_ title: String, symbol: String, action: Selector, key: String, modifiers: NSEvent.ModifierFlags) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        item.image = SnapSailStyle.symbol(symbol, size: 14, weight: .regular)
        item.keyEquivalentModifierMask = modifiers
        return item
    }

    @objc private func captureArea() { onCaptureArea?() }
    @objc private func captureWindow() { onCaptureWindow?() }
    @objc private func scrollingCapture() { onScrollingCapture?() }
    @objc private func showHistory() { onHistory?() }
    @objc private func showSettings() { onSettings?() }

    @objc private func showAbout() {
        NSApplication.shared.orderFrontStandardAboutPanel(options: [
            .applicationName: "SnapSail",
            .applicationVersion: "0.1.0",
            .credits: NSAttributedString(string: L10n.text(.tagline))
        ])
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
