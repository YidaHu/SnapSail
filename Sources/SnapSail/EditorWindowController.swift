import AppKit
import SnapSailCore

final class EditorWindowController: NSWindowController, NSWindowDelegate {
    private let canvas: AnnotationCanvasView
    private let preferences: AppPreferences
    private let onClose: (EditorWindowController) -> Void
    private var toolButtons: [SymbolButton] = []
    private weak var undoButton: SymbolButton?
    private weak var redoButton: SymbolButton?

    init(image: CGImage, preferences: AppPreferences, onClose: @escaping (EditorWindowController) -> Void) {
        canvas = AnnotationCanvasView(image: image)
        self.preferences = preferences
        self.onClose = onClose

        let visible = NSScreen.main?.visibleFrame.size ?? NSSize(width: 1200, height: 800)
        let size = NSSize(width: min(1100, visible.width * 0.82), height: min(760, visible.height * 0.82))
        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.text(.editorTitle)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor(calibratedWhite: 0.12, alpha: 1)
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

        let toolbar = NSVisualEffectView(frame: CGRect(x: 0, y: size.height - 56, width: size.width, height: 56))
        toolbar.material = .headerView
        toolbar.blendingMode = .withinWindow
        toolbar.autoresizingMask = [.width, .minYMargin]
        content.addSubview(toolbar)

        var x: CGFloat = 76
        for tool in AnnotationTool.allCases {
            let button = SymbolButton(symbol: tool.symbolName, toolTip: tool.title, target: self, action: #selector(selectTool(_:)))
            button.tag = tool.rawValue
            button.frame = CGRect(x: x, y: 11, width: 34, height: 34)
            if tool == .arrow { button.isSelected = true }
            toolbar.addSubview(button)
            toolButtons.append(button)
            x += 38
        }

        let separator = NSBox(frame: CGRect(x: x + 3, y: 16, width: 1, height: 24))
        separator.boxType = .separator
        toolbar.addSubview(separator)

        let color = SymbolButton(symbol: "paintpalette", toolTip: L10n.text(.color), target: self, action: #selector(chooseColor))
        color.frame = CGRect(x: x + 13, y: 11, width: 34, height: 34)
        toolbar.addSubview(color)

        let scroll = NSScrollView(frame: CGRect(x: 0, y: 56, width: size.width, height: size.height - 112))
        scroll.autoresizingMask = [.width, .height]
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = true
        scroll.drawsBackground = true
        scroll.backgroundColor = NSColor(calibratedWhite: 0.105, alpha: 1)
        canvas.frame = scroll.bounds.insetBy(dx: 28, dy: 28)
        canvas.autoresizingMask = [.width, .height]
        scroll.documentView = canvas
        content.addSubview(scroll)

        let bottom = NSVisualEffectView(frame: CGRect(x: 0, y: 0, width: size.width, height: 56))
        bottom.material = .headerView
        bottom.blendingMode = .withinWindow
        bottom.autoresizingMask = [.width, .maxYMargin]
        content.addSubview(bottom)

        let undo = SymbolButton(symbol: "arrow.uturn.backward", toolTip: L10n.text(.undo), target: self, action: #selector(undo))
        undo.frame = CGRect(x: 16, y: 11, width: 34, height: 34)
        bottom.addSubview(undo)
        undoButton = undo

        let redo = SymbolButton(symbol: "arrow.uturn.forward", toolTip: L10n.text(.redo), target: self, action: #selector(redo))
        redo.frame = CGRect(x: 54, y: 11, width: 34, height: 34)
        bottom.addSubview(redo)
        redoButton = redo

        let save = PrimaryButton(title: L10n.text(.save), target: self, action: #selector(save))
        save.frame = CGRect(x: size.width - 104, y: 13, width: 88, height: 30)
        bottom.addSubview(save)
        save.autoresizingMask = [.minXMargin]

        let copy = actionButton(L10n.text(.copy), symbol: "doc.on.doc", action: #selector(copyImage), x: size.width - 198, to: bottom)
        copy.autoresizingMask = [.minXMargin]
        let pin = actionButton(L10n.text(.pin), symbol: "pin", action: #selector(pinImage), x: size.width - 280, to: bottom)
        pin.autoresizingMask = [.minXMargin]
        updateUndoButtons()
    }

    @discardableResult
    private func actionButton(_ title: String, symbol: String, action: Selector, x: CGFloat, to view: NSView) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.image = SnapSailStyle.symbol(symbol, size: 13)
        button.imagePosition = .imageLeading
        button.bezelStyle = .rounded
        button.frame = CGRect(x: x, y: 13, width: 76, height: 30)
        view.addSubview(button)
        return button
    }

    @objc private func selectTool(_ sender: NSButton) {
        guard let tool = AnnotationTool(rawValue: sender.tag) else { return }
        canvas.activeTool = tool
        toolButtons.forEach { $0.isSelected = $0 === sender }
    }

    @objc private func undo() { canvas.undo() }
    @objc private func redo() { canvas.redo() }
    private func updateUndoButtons() {
        undoButton?.isEnabled = canvas.canUndo
        redoButton?.isEnabled = canvas.canRedo
    }

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
        window.isReleasedWhenClosed = false
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
    func windowWillClose(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.onClose(self)
        }
    }
}

private final class PinImageView: NSImageView {
    override func mouseDown(with event: NSEvent) {
        switch PinInteraction.primaryAction(clickCount: event.clickCount) {
        case .close:
            window?.close()
        case .drag:
            window?.performDrag(with: event)
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()
        let close = NSMenuItem(title: L10n.text(.closePinnedImage), action: #selector(closeWindow), keyEquivalent: "")
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
