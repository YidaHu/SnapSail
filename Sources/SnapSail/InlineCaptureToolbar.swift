import AppKit
import SnapSailCore

final class InlineCaptureToolbar: NSView {
    static let preferredSize = CGSize(width: 700, height: 66)

    var onToolSelected: ((InlineAnnotationTool?) -> Void)?
    var onColorChanged: ((InlineAnnotationColor) -> Void)?
    var onUndo: (() -> Void)?
    var onRedo: (() -> Void)?
    var onCancel: (() -> Void)?
    var onScroll: (() -> Void)?
    var onSave: (() -> Void)?
    var onCopy: (() -> Void)?

    private var toolButtons: [InlineAnnotationTool: InlineToolbarButton] = [:]
    private weak var undoButton: InlineToolbarButton?
    private weak var redoButton: InlineToolbarButton?
    private weak var colorButton: InlineToolbarButton?
    private var activeTool: InlineAnnotationTool?
    private let colors: [InlineAnnotationColor] = [
        .red,
        InlineAnnotationColor(red: 1, green: 0.48, blue: 0.08),
        InlineAnnotationColor(red: 1, green: 0.78, blue: 0.08),
        InlineAnnotationColor(red: 0.18, green: 0.72, blue: 0.34),
        InlineAnnotationColor(red: 0.08, green: 0.46, blue: 0.96),
        InlineAnnotationColor(red: 0.58, green: 0.30, blue: 0.94),
        InlineAnnotationColor(red: 0.12, green: 0.12, blue: 0.14)
    ]
    private var colorIndex = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = SnapSailStyle.captureToolbarBackground.cgColor
        layer?.cornerRadius = frameRect.height / 2
        layer?.borderWidth = 0.5
        layer?.borderColor = NSColor.black.withAlphaComponent(0.08).cgColor
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.24
        layer?.shadowRadius = 16
        layer?.shadowOffset = CGSize(width: 0, height: -5)
        buildButtons()
    }

    required init?(coder: NSCoder) { nil }

    func updateHistory(canUndo: Bool, canRedo: Bool) {
        undoButton?.isEnabled = canUndo
        redoButton?.isEnabled = canRedo
    }

    func clearActiveTool() {
        activeTool = nil
        toolButtons.values.forEach { $0.isSelected = false }
    }

    private func buildButtons() {
        let tools: [(InlineAnnotationTool, String, String)] = [
            (.rectangle, "rectangle", L10n.text(.rectangle)),
            (.ellipse, "circle", L10n.text(.ellipse)),
            (.line, "line.diagonal", L10n.text(.line)),
            (.arrow, "arrow.up.right", L10n.text(.arrow)),
            (.pen, "pencil.tip", L10n.text(.pen)),
            (.pixelate, "square.grid.3x3", L10n.text(.pixelate)),
            (.text, "textformat", L10n.text(.text)),
            (.number, "1.circle.fill", L10n.text(.number)),
            (.highlight, "highlighter", L10n.text(.highlight))
        ]

        var x: CGFloat = 14
        for (tool, symbol, title) in tools {
            let button = addButton(symbol: symbol, title: title, x: x, action: #selector(selectTool(_:)))
            button.tag = tool.rawValue
            toolButtons[tool] = button
            x += 40
        }

        addSeparator(x: x + 2)
        x += 14

        let color = addButton(symbol: "paintpalette.fill", title: L10n.text(.changeColor), x: x, action: #selector(cycleColor))
        color.accentColor = nsColor(colors[colorIndex])
        colorButton = color
        x += 40

        let undo = addButton(symbol: "arrow.uturn.backward", title: L10n.text(.undo), x: x, action: #selector(undo))
        undo.isEnabled = false
        undoButton = undo
        x += 40

        let redo = addButton(symbol: "arrow.uturn.forward", title: L10n.text(.redo), x: x, action: #selector(redo))
        redo.isEnabled = false
        redoButton = redo
        x += 40

        let cancel = addButton(symbol: "xmark", title: L10n.text(.cancel), x: x, action: #selector(cancel))
        cancel.accentColor = .systemRed
        x += 40

        addSeparator(x: x + 2)
        x += 14

        _ = addButton(symbol: "arrow.down.to.line.compact", title: L10n.text(.scrollingCapture), x: x, action: #selector(startScrollingCapture))
        x += 40
        _ = addButton(symbol: "tray.and.arrow.down", title: L10n.text(.saveAndCopy), x: x, action: #selector(save))
        x += 40
        let copy = addButton(symbol: "doc.on.doc.fill", title: L10n.text(.copyAndFinish), x: x, action: #selector(copyImage))
        copy.isEmphasized = true
    }

    @discardableResult
    private func addButton(symbol: String, title: String, x: CGFloat, action: Selector) -> InlineToolbarButton {
        let button = InlineToolbarButton(symbol: symbol, title: title, target: self, action: action)
        button.frame = CGRect(x: x, y: 11, width: 40, height: 44)
        addSubview(button)
        return button
    }

    private func addSeparator(x: CGFloat) {
        let separator = NSView(frame: CGRect(x: x, y: 17, width: 1, height: 32))
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.18).cgColor
        addSubview(separator)
    }

    @objc private func selectTool(_ sender: InlineToolbarButton) {
        guard let tool = InlineAnnotationTool(rawValue: sender.tag) else { return }
        activeTool = activeTool == tool ? nil : tool
        toolButtons.forEach { $0.value.isSelected = $0.key == activeTool }
        onToolSelected?(activeTool)
    }

    @objc private func cycleColor() {
        colorIndex = (colorIndex + 1) % colors.count
        let color = colors[colorIndex]
        colorButton?.accentColor = nsColor(color)
        onColorChanged?(color)
    }

    @objc private func undo() { onUndo?() }
    @objc private func redo() { onRedo?() }
    @objc private func cancel() { onCancel?() }
    @objc private func startScrollingCapture() { onScroll?() }
    @objc private func save() { onSave?() }
    @objc private func copyImage() { onCopy?() }

    private func nsColor(_ color: InlineAnnotationColor) -> NSColor {
        NSColor(
            calibratedRed: color.red,
            green: color.green,
            blue: color.blue,
            alpha: color.alpha
        )
    }
}

private final class InlineToolbarButton: NSButton {
    var isSelected = false { didSet { updateAppearance() } }
    var isEmphasized = false { didSet { updateAppearance() } }
    var accentColor = SnapSailStyle.accent { didSet { updateAppearance() } }
    private var hovered = false
    private var tracking: NSTrackingArea?

    init(symbol: String, title: String, target: AnyObject?, action: Selector?) {
        super.init(frame: .zero)
        image = SnapSailStyle.symbol(symbol, size: 22, weight: .regular)
        imagePosition = .imageOnly
        isBordered = false
        focusRingType = .none
        toolTip = title
        self.target = target
        self.action = action
        wantsLayer = true
        layer?.cornerRadius = 9
        updateAppearance()
    }

    required init?(coder: NSCoder) { nil }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        tracking = area
    }

    override func mouseEntered(with event: NSEvent) {
        hovered = true
        updateAppearance()
    }

    override func mouseExited(with event: NSEvent) {
        hovered = false
        updateAppearance()
    }

    override var isEnabled: Bool { didSet { updateAppearance() } }

    private func updateAppearance() {
        alphaValue = isEnabled ? 1 : 0.28
        if isSelected {
            layer?.backgroundColor = accentColor.withAlphaComponent(0.14).cgColor
            contentTintColor = accentColor
        } else if isEmphasized {
            layer?.backgroundColor = SnapSailStyle.accent.withAlphaComponent(0.12).cgColor
            contentTintColor = SnapSailStyle.accent
        } else if hovered && isEnabled {
            layer?.backgroundColor = NSColor.black.withAlphaComponent(0.07).cgColor
            contentTintColor = accentColor == .systemRed ? .systemRed : SnapSailStyle.captureToolbarForeground
        } else {
            layer?.backgroundColor = NSColor.clear.cgColor
            contentTintColor = accentColor == .systemRed ? .systemRed : SnapSailStyle.captureToolbarForeground
        }
    }
}
