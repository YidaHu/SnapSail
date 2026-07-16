import AppKit

enum SnapSailStyle {
    static let accent = NSColor.systemBlue
    static let selectionFill = NSColor.systemBlue.withAlphaComponent(0.08)
    static let overlayDim = NSColor.black.withAlphaComponent(0.18)
    static let captureToolbarBackground = NSColor(calibratedWhite: 0.985, alpha: 0.98)
    static let captureToolbarForeground = NSColor(calibratedWhite: 0.22, alpha: 1)
    static let cardCornerRadius: CGFloat = 11
    static let controlHeight: CGFloat = 30
    static let space8: CGFloat = 8
    static let space12: CGFloat = 12
    static let space16: CGFloat = 16
    static let space24: CGFloat = 24
    static let space32: CGFloat = 32

    static func symbol(_ name: String, size: CGFloat = 16, weight: NSFont.Weight = .medium) -> NSImage? {
        let configuration = NSImage.SymbolConfiguration(pointSize: size, weight: weight)
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(configuration)
        image?.isTemplate = true
        return image
    }
}

final class CircularSymbolButton: NSButton {
    private var tracking: NSTrackingArea?
    private var hovered = false

    init(symbol: String, toolTip: String, target: AnyObject?, action: Selector?) {
        super.init(frame: CGRect(x: 0, y: 0, width: 46, height: 46))
        image = SnapSailStyle.symbol(symbol, size: 23, weight: .semibold)
        imagePosition = .imageOnly
        isBordered = false
        focusRingType = .none
        self.toolTip = toolTip
        self.target = target
        self.action = action
        wantsLayer = true
        layer?.cornerRadius = 23
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.22
        layer?.shadowRadius = 8
        layer?.shadowOffset = CGSize(width: 0, height: -3)
        contentTintColor = SnapSailStyle.captureToolbarForeground
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

    private func updateAppearance() {
        layer?.backgroundColor = (hovered ? NSColor(calibratedWhite: 0.92, alpha: 1) : .white).cgColor
    }
}

final class MaterialCardView: NSVisualEffectView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        material = .popover
        blendingMode = .behindWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = SnapSailStyle.cardCornerRadius
        layer?.masksToBounds = false
        layer?.borderWidth = 0.5
        layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.5).cgColor
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.22
        layer?.shadowRadius = 12
        layer?.shadowOffset = CGSize(width: 0, height: -4)
    }

    required init?(coder: NSCoder) { nil }
}

class SymbolButton: NSButton {
    private let symbolName: String
    private var trackingAreaRef: NSTrackingArea?
    var isSelected = false { didSet { updateAppearance(hovered: false) } }

    init(symbol: String, toolTip: String, target: AnyObject?, action: Selector?) {
        symbolName = symbol
        super.init(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        image = SnapSailStyle.symbol(symbol)
        imagePosition = .imageOnly
        bezelStyle = .regularSquare
        isBordered = false
        self.toolTip = toolTip
        self.target = target
        self.action = action
        wantsLayer = true
        layer?.cornerRadius = 7
        focusRingType = .none
        updateAppearance(hovered: false)
    }

    required init?(coder: NSCoder) { nil }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaRef { removeTrackingArea(trackingAreaRef) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingAreaRef = area
    }

    override func mouseEntered(with event: NSEvent) { updateAppearance(hovered: true) }
    override func mouseExited(with event: NSEvent) { updateAppearance(hovered: false) }

    private func updateAppearance(hovered: Bool) {
        if isSelected {
            layer?.backgroundColor = SnapSailStyle.accent.cgColor
            contentTintColor = .white
        } else if hovered {
            layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.08).cgColor
            contentTintColor = .labelColor
        } else {
            layer?.backgroundColor = NSColor.clear.cgColor
            contentTintColor = .labelColor
        }
    }
}

final class PillLabel: NSTextField {
    init(text: String = "", color: NSColor = .systemBlue) {
        super.init(frame: .zero)
        stringValue = text
        isEditable = false
        isSelectable = false
        isBezeled = false
        drawsBackground = true
        backgroundColor = color.withAlphaComponent(0.92)
        textColor = .white
        alignment = .center
        font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.masksToBounds = true
    }

    required init?(coder: NSCoder) { nil }
}

final class MeasurementPillView: NSView {
    private let widthLabel = NSTextField(labelWithString: "0")
    private let lockView = NSImageView()
    private let heightLabel = NSTextField(labelWithString: "0")
    private let unitLabel = NSTextField(labelWithString: "pt")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = SnapSailStyle.accent.cgColor
        layer?.cornerRadius = 7
        layer?.shadowColor = SnapSailStyle.accent.cgColor
        layer?.shadowOpacity = 0.32
        layer?.shadowRadius = 10
        layer?.shadowOffset = CGSize(width: 0, height: -3)

        for label in [widthLabel, heightLabel] {
            label.font = .monospacedDigitSystemFont(ofSize: 20, weight: .semibold)
            label.textColor = .white
            label.alignment = .center
            addSubview(label)
        }
        unitLabel.font = .systemFont(ofSize: 17, weight: .medium)
        unitLabel.textColor = .white.withAlphaComponent(0.94)
        unitLabel.alignment = .left
        addSubview(unitLabel)
        lockView.image = SnapSailStyle.symbol("lock.fill", size: 14, weight: .semibold)
        lockView.contentTintColor = .white
        addSubview(lockView)
    }

    required init?(coder: NSCoder) { nil }

    func setSize(_ size: CGSize) {
        widthLabel.stringValue = "\(Int(size.width))"
        heightLabel.stringValue = "\(Int(size.height))"
    }

    override func layout() {
        super.layout()
        widthLabel.frame = CGRect(x: 14, y: 11, width: 72, height: 28)
        lockView.frame = CGRect(x: 91, y: 17, width: 16, height: 16)
        heightLabel.frame = CGRect(x: 112, y: 11, width: 72, height: 28)
        unitLabel.frame = CGRect(x: 190, y: 13, width: 38, height: 24)
    }
}

final class PrimaryButton: NSButton {
    init(title: String, target: AnyObject?, action: Selector?) {
        super.init(frame: .zero)
        self.title = title
        self.target = target
        self.action = action
        bezelStyle = .rounded
        keyEquivalent = "\r"
        contentTintColor = .white
        wantsLayer = true
        layer?.backgroundColor = SnapSailStyle.accent.cgColor
        layer?.cornerRadius = 7
        isBordered = false
        font = .systemFont(ofSize: 13, weight: .semibold)
    }

    required init?(coder: NSCoder) { nil }
}
