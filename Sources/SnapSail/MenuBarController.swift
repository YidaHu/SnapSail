import AppKit

final class MenuBarController: NSObject {
    var onCaptureArea: (() -> Void)?
    var onCaptureWindow: (() -> Void)?
    var onScrollingCapture: (() -> Void)?
    var onHistory: (() -> Void)?
    var onSettings: (() -> Void)?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

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
        menu.addItem(item("Capture Area", action: #selector(captureArea), key: "2"))
        menu.addItem(item("Capture Window", action: #selector(captureWindow), key: "3"))
        menu.addItem(item("Scrolling Capture", action: #selector(scrollingCapture), key: "4"))
        menu.addItem(.separator())
        menu.addItem(item("Capture History", action: #selector(showHistory), key: "h"))
        menu.addItem(item("Settings…", action: #selector(showSettings), key: ","))
        menu.addItem(.separator())

        let about = NSMenuItem(title: "About SnapSail", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(title: "Quit SnapSail", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
        return menu
    }

    private func item(_ title: String, action: Selector, key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        item.keyEquivalentModifierMask = [.command, .shift]
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
            .credits: NSAttributedString(string: "Capture More. Scroll Less.")
        ])
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
