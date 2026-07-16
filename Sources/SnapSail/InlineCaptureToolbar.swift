import AppKit
import SnapSailCore

final class InlineCaptureToolbar: NSView {
    static let preferredSize = SnapSailStyle.captureToolbarSize

    private enum Metrics {
        static let outerPadding: CGFloat = 12
        static let buttonWidth: CGFloat = 40
        static let buttonHeight: CGFloat = 42
        static let buttonGap: CGFloat = 4
        static let separatorLeadingSpace: CGFloat = 6
        static let separatorWidth: CGFloat = 1
        static let separatorTrailingSpace: CGFloat = 7
    }

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
        layer?.cornerRadius = SnapSailStyle.captureToolbarCornerRadius
        layer?.borderWidth = 0.5
        layer?.borderColor = NSColor.black.withAlphaComponent(0.07).cgColor
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.20
        layer?.shadowRadius = 18
        layer?.shadowOffset = CGSize(width: 0, height: -7)
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
        let tools: [(InlineAnnotationTool, String, String, String)] = [
            (.rectangle, "rectangle", L10n.text(.rectangle), "rectangle"),
            (.ellipse, "circle", L10n.text(.ellipse), "ellipse"),
            (.line, "line.diagonal", L10n.text(.line), "line"),
            (.arrow, "arrow.up.right", L10n.text(.arrow), "arrow"),
            (.pen, "pencil.tip", L10n.text(.pen), "pen"),
            (.pixelate, "square.grid.3x3", L10n.text(.pixelate), "pixelate"),
            (.text, "textformat", L10n.text(.text), "text"),
            (.number, "1.circle.fill", L10n.text(.number), "number"),
            (.highlight, "highlighter", L10n.text(.highlight), "highlight")
        ]

        var x = Metrics.outerPadding
        for (index, item) in tools.enumerated() {
            let (tool, symbol, title, identifier) = item
            let button = addButton(
                symbol: symbol,
                title: title,
                identifier: "capture.tool.\(identifier)",
                x: x,
                action: #selector(selectTool(_:))
            )
            button.tag = tool.rawValue
            toolButtons[tool] = button
            advanceButton(at: &x, addGap: index < tools.count - 1)
        }

        addSeparator(at: &x)

        let color = addButton(
            symbol: "paintpalette.fill",
            title: L10n.text(.changeColor),
            identifier: "capture.color",
            x: x,
            action: #selector(cycleColor)
        )
        color.accentColor = nsColor(colors[colorIndex])
        color.usesAccentTint = true
        colorButton = color
        advanceButton(at: &x)

        let undo = addButton(
            symbol: "arrow.uturn.backward",
            title: L10n.text(.undo),
            identifier: "capture.undo",
            x: x,
            action: #selector(undo)
        )
        undo.isEnabled = false
        undoButton = undo
        advanceButton(at: &x)

        let redo = addButton(
            symbol: "arrow.uturn.forward",
            title: L10n.text(.redo),
            identifier: "capture.redo",
            x: x,
            action: #selector(redo)
        )
        redo.isEnabled = false
        redoButton = redo
        advanceButton(at: &x)

        let cancel = addButton(
            symbol: "xmark",
            title: L10n.text(.cancel),
            identifier: "capture.cancel",
            x: x,
            action: #selector(cancel)
        )
        cancel.role = .destructive
        advanceButton(at: &x, addGap: false)

        addSeparator(at: &x)

        _ = addButton(
            symbol: "arrow.down.to.line.compact",
            title: L10n.text(.scrollingCapture),
            identifier: "capture.scroll",
            x: x,
            action: #selector(startScrollingCapture)
        )
        advanceButton(at: &x)
        _ = addButton(
            symbol: "tray.and.arrow.down",
            title: L10n.text(.saveAndCopy),
            identifier: "capture.save",
            x: x,
            action: #selector(save)
        )
        advanceButton(at: &x)
        let copy = addButton(
            symbol: "doc.on.doc.fill",
            title: L10n.text(.copyAndFinish),
            identifier: "capture.copy",
            x: x,
            action: #selector(copyImage)
        )
        copy.role = .primary
    }

    @discardableResult
    private func addButton(
        symbol: String,
        title: String,
        identifier: String,
        x: CGFloat,
        action: Selector
    ) -> InlineToolbarButton {
        let button = InlineToolbarButton(symbol: symbol, title: title, target: self, action: action)
        button.identifier = NSUserInterfaceItemIdentifier(identifier)
        button.frame = CGRect(
            x: x,
            y: (Self.preferredSize.height - Metrics.buttonHeight) / 2,
            width: Metrics.buttonWidth,
            height: Metrics.buttonHeight
        )
        addSubview(button)
        return button
    }

    private func advanceButton(at x: inout CGFloat, addGap: Bool = true) {
        x += Metrics.buttonWidth
        if addGap { x += Metrics.buttonGap }
    }

    private func addSeparator(at x: inout CGFloat) {
        x += Metrics.separatorLeadingSpace
        let separator = NSView(frame: CGRect(
            x: x,
            y: (Self.preferredSize.height - 26) / 2,
            width: Metrics.separatorWidth,
            height: 26
        ))
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.14).cgColor
        addSubview(separator)
        x += Metrics.separatorWidth + Metrics.separatorTrailingSpace
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
    enum Role {
        case standard
        case destructive
        case primary
    }

    var isSelected = false { didSet { updateAppearance() } }
    var role = Role.standard { didSet { updateAppearance() } }
    var accentColor = SnapSailStyle.accent { didSet { updateAppearance() } }
    var usesAccentTint = false { didSet { updateAppearance() } }
    private var hovered = false
    private var tracking: NSTrackingArea?

    init(symbol: String, title: String, target: AnyObject?, action: Selector?) {
        super.init(frame: .zero)
        image = SnapSailStyle.symbol(symbol, size: 20, weight: .medium)
        imagePosition = .imageOnly
        isBordered = false
        focusRingType = .none
        toolTip = title
        self.target = target
        self.action = action
        wantsLayer = true
        layer?.cornerRadius = 11
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
            layer?.backgroundColor = SnapSailStyle.captureToolbarSelectionBackground.cgColor
            contentTintColor = SnapSailStyle.accent
        } else if role == .primary {
            layer?.backgroundColor = primaryBackground(hovered: hovered).cgColor
            contentTintColor = .white
        } else if hovered && isEnabled {
            layer?.backgroundColor = (
                role == .destructive
                    ? SnapSailStyle.captureToolbarDestructiveHoverBackground
                    : SnapSailStyle.captureToolbarHoverBackground
            ).cgColor
            contentTintColor = foregroundColor
        } else {
            layer?.backgroundColor = NSColor.clear.cgColor
            contentTintColor = foregroundColor
        }
    }

    private var foregroundColor: NSColor {
        if role == .destructive { return .systemRed }
        if usesAccentTint { return accentColor }
        return SnapSailStyle.captureToolbarForeground
    }

    private func primaryBackground(hovered: Bool) -> NSColor {
        guard hovered else { return SnapSailStyle.accent }
        return SnapSailStyle.accent.blended(withFraction: 0.12, of: .black) ?? SnapSailStyle.accent
    }
}
