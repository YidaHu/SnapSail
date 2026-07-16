import AppKit

final class EditorWindowController: NSWindowController, NSWindowDelegate {
    private let canvas: AnnotationCanvasView
    private let preferences: AppPreferences
    private let onClose: (EditorWindowController) -> Void
    private var toolButtons: [NSButton] = []

    init(image: CGImage, preferences: AppPreferences, onClose: @escaping (EditorWindowController) -> Void) {
        canvas = AnnotationCanvasView(image: image)
        self.preferences = preferences
        self.onClose = onClose

        let visible = NSScreen.main?.visibleFrame.size ?? NSSize(width: 1200, height: 800)
        let size = NSSize(width: min(1100, visible.width * 0.82), height: min(760, visible.height * 0.82))
        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "SnapSail Editor"
        window.center()
        super.init(window: window)
        window.delegate = self
        buildInterface(size: size)
        canvas.onChange = { [weak self] in self?.updateUndoButtons() }
    }

    required init?(coder: NSCoder) { nil }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        NSApplication.shared.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) { onClose(self) }

    private func buildInterface(size: NSSize) {
        guard let content = window?.contentView else { return }

        let toolbar = NSVisualEffectView(frame: CGRect(x: 0, y: size.height - 52, width: size.width, height: 52))
        toolbar.material = .headerView
        toolbar.blendingMode = .withinWindow
        toolbar.autoresizingMask = [.width, .minYMargin]
        content.addSubview(toolbar)

        var x: CGFloat = 12
        for tool in AnnotationTool.allCases {
            let button = NSButton(title: tool.title, target: self, action: #selector(selectTool(_:)))
            button.tag = tool.rawValue
            button.setButtonType(.toggle)
            button.bezelStyle = .texturedRounded
            button.sizeToFit()
            button.frame = CGRect(x: x, y: 11, width: max(58, button.frame.width + 10), height: 30)
            if tool == .arrow { button.state = .on }
            toolbar.addSubview(button)
            toolButtons.append(button)
            x += button.frame.width + 5
        }

        let scroll = NSScrollView(frame: CGRect(x: 0, y: 54, width: size.width, height: size.height - 106))
        scroll.autoresizingMask = [.width, .height]
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = true
        scroll.backgroundColor = .controlBackgroundColor
        canvas.frame = scroll.bounds.insetBy(dx: 24, dy: 24)
        canvas.autoresizingMask = [.width, .height]
        scroll.documentView = canvas
        content.addSubview(scroll)

        let bottom = NSVisualEffectView(frame: CGRect(x: 0, y: 0, width: size.width, height: 54))
        bottom.material = .headerView
        bottom.blendingMode = .withinWindow
        bottom.autoresizingMask = [.width, .maxYMargin]
        content.addSubview(bottom)

        addButton("Undo", action: #selector(undo), x: 14, to: bottom)
        addButton("Redo", action: #selector(redo), x: 88, to: bottom)
        addButton("Color", action: #selector(chooseColor), x: 174, to: bottom)

        let save = addButton("Save…", action: #selector(save), x: size.width - 96, to: bottom)
        save.autoresizingMask = [.minXMargin]
        let copy = addButton("Copy", action: #selector(copyImage), x: size.width - 176, to: bottom)
        copy.autoresizingMask = [.minXMargin]
        let pin = addButton("Pin", action: #selector(pinImage), x: size.width - 250, to: bottom)
        pin.autoresizingMask = [.minXMargin]
    }

    @discardableResult
    private func addButton(_ title: String, action: Selector, x: CGFloat, to view: NSView) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.frame = CGRect(x: x, y: 12, width: 70, height: 30)
        view.addSubview(button)
        return button
    }

    @objc private func selectTool(_ sender: NSButton) {
        guard let tool = AnnotationTool(rawValue: sender.tag) else { return }
        canvas.activeTool = tool
        toolButtons.forEach { $0.state = $0 === sender ? .on : .off }
    }

    @objc private func undo() { canvas.undo() }
    @objc private func redo() { canvas.redo() }
    private func updateUndoButtons() {}

    @objc private func chooseColor() {
        let panel = NSColorPanel.shared
        panel.color = canvas.activeColor
        panel.setTarget(self)
        panel.setAction(#selector(colorChanged(_:)))
        panel.orderFront(nil)
    }

    @objc private func colorChanged(_ sender: NSColorPanel) { canvas.activeColor = sender.color }

    @objc private func copyImage() {
        guard let image = canvas.renderedImage() else { return }
        ImageExporter.copyToPasteboard(image)
        NSSound(named: "Tink")?.play()
    }

    @objc private func save() {
        guard let image = canvas.renderedImage() else { return }
        ImageExporter.presentSavePanel(for: image, preferences: preferences, window: window)
    }

    @objc private func pinImage() {
        guard let image = canvas.renderedImage() else { return }
        PinWindowRegistry.shared.pin(image)
    }
}

final class PinWindowRegistry: NSObject, NSWindowDelegate {
    static let shared = PinWindowRegistry()
    private var controllers: [PinWindowController] = []

    func pin(_ image: CGImage) {
        let controller = PinWindowController(image: image) { [weak self] controller in
            self?.controllers.removeAll { $0 === controller }
        }
        controllers.append(controller)
        controller.show()
    }
}

final class PinWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let onClose: (PinWindowController) -> Void

    init(image: CGImage, onClose: @escaping (PinWindowController) -> Void) {
        self.onClose = onClose
        let maximum = NSSize(width: 560, height: 560)
        let scale = min(1, maximum.width / CGFloat(image.width), maximum.height / CGFloat(image.height))
        let size = NSSize(width: max(120, CGFloat(image.width) * scale), height: max(80, CGFloat(image.height) * scale))
        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.hasShadow = true
        window.backgroundColor = .clear
        let imageView = PinImageView(frame: CGRect(origin: .zero, size: size))
        imageView.image = NSImage(cgImage: image, size: size)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.autoresizingMask = [.width, .height]
        window.contentView = imageView
        window.center()
        self.window = window
        super.init()
        window.delegate = self
    }

    func show() { window?.makeKeyAndOrderFront(nil) }
    func windowWillClose(_ notification: Notification) { onClose(self) }
}

private final class PinImageView: NSImageView {
    override func mouseDown(with event: NSEvent) {
        if event.clickCount >= 2 { window?.close() }
        else { super.mouseDown(with: event) }
    }

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()
        let close = NSMenuItem(title: "Close Pinned Image", action: #selector(closeWindow), keyEquivalent: "")
        close.target = self
        menu.addItem(close)
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    override func scrollWheel(with event: NSEvent) {
        guard event.modifierFlags.contains(.option), let window else {
            super.scrollWheel(with: event)
            return
        }
        window.alphaValue = max(0.2, min(1, window.alphaValue + event.scrollingDeltaY * 0.01))
    }

    @objc private func closeWindow() { window?.close() }
}
