import AppKit
import SnapSailCore

enum SelectionMode {
    case region
    case window
}

enum SelectionResult {
    case region(CGRect)
    case windows([WindowDescriptor])
}

enum SelectionAction {
    case capture
    case scroll
    case copy
    case pin
}

struct SelectionOutcome {
    let selection: SelectionResult
    let action: SelectionAction
}

final class SelectionOverlayController: NSObject {
    private var mode: SelectionMode
    private let captureService: CaptureService
    private let completion: (SelectionOutcome?) -> Void
    private var overlayWindows: [NSWindow] = []
    private var overlayViews: [SelectionOverlayView] = []
    private var availableWindows: [WindowDescriptor] = []
    private var highlightedWindow: WindowDescriptor?
    private var selectedWindowIDs = Set<CGWindowID>()
    private weak var activeView: SelectionOverlayView?
    private var completed = false

    init(mode: SelectionMode, captureService: CaptureService, completion: @escaping (SelectionOutcome?) -> Void) {
        self.mode = mode
        self.captureService = captureService
        self.completion = completion
        super.init()
    }

    func begin() {
        if mode == .window { availableWindows = captureService.windows() }
        for screen in NSScreen.screens {
            let window = OverlayWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.level = .screenSaver
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.ignoresMouseEvents = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            let view = SelectionOverlayView(screen: screen, controller: self)
            window.contentView = view
            window.acceptsMouseMovedEvents = true
            overlayWindows.append(window)
            overlayViews.append(view)
            window.orderFrontRegardless()
        }
        overlayWindows.first?.makeKey()
        NSCursor.crosshair.push()
    }

    func cancel() { finish(nil) }

    func regionWillBegin(in view: SelectionOverlayView) {
        activeView = view
        overlayViews.filter { $0 !== view }.forEach { $0.clearRegion() }
    }

    func mouseMoved(to globalPoint: CGPoint, in view: SelectionOverlayView) {
        activeView = view
        guard mode == .window else { return }
        highlightedWindow = captureService.window(atAppKitPoint: globalPoint, in: availableWindows)
        redraw()
    }

    func windowClicked(from view: SelectionOverlayView, modifiers: NSEvent.ModifierFlags) {
        guard let highlightedWindow else { return }
        activeView = view
        if modifiers.contains(.shift) {
            if selectedWindowIDs.contains(highlightedWindow.id) {
                selectedWindowIDs.remove(highlightedWindow.id)
            } else {
                selectedWindowIDs.insert(highlightedWindow.id)
            }
        } else {
            selectedWindowIDs = [highlightedWindow.id]
        }
        redraw()
    }

    func perform(_ action: SelectionAction) {
        switch mode {
        case .region:
            guard let view = activeView, let globalRect = view.globalSelectionRect else { return }
            finish(SelectionOutcome(selection: .region(globalRect.integral), action: action))
        case .window:
            var selected = availableWindows.filter { selectedWindowIDs.contains($0.id) }
            if selected.isEmpty, let highlightedWindow { selected = [highlightedWindow] }
            guard !selected.isEmpty else { return }
            finish(SelectionOutcome(selection: .windows(selected), action: action))
        }
    }

    func toggleMode() {
        mode = mode == .region ? .window : .region
        if mode == .window, availableWindows.isEmpty { availableWindows = captureService.windows() }
        overlayViews.forEach { $0.modeDidChange() }
        redraw()
    }

    func nudgeSelection(dx: CGFloat, dy: CGFloat, accelerated: Bool) {
        guard mode == .region else { return }
        activeView?.nudge(dx: dx, dy: dy, accelerated: accelerated)
    }

    func loupeImage(at appKitPoint: CGPoint, below windowNumber: Int) -> CGImage? {
        let size = CGSize(width: 24, height: 17)
        let appKitRect = CGRect(
            x: appKitPoint.x - size.width / 2,
            y: appKitPoint.y - size.height / 2,
            width: size.width,
            height: size.height
        )
        return CGWindowListCreateImage(
            captureService.quartzRect(fromAppKitRect: appKitRect),
            .optionOnScreenBelowWindow,
            CGWindowID(windowNumber),
            [.bestResolution]
        )
    }

    func highlightRects(for screen: NSScreen) -> [(CGRect, Bool)] {
        availableWindows.compactMap { descriptor in
            let selected = selectedWindowIDs.contains(descriptor.id)
            guard selected || descriptor.id == highlightedWindow?.id else { return nil }
            let global = descriptor.appKitBounds(primaryScreenHeight: captureService.primaryScreenHeight)
            return (
                CGRect(
                    x: global.minX - screen.frame.minX,
                    y: global.minY - screen.frame.minY,
                    width: global.width,
                    height: global.height
                ),
                selected
            )
        }
    }

    var selectionMode: SelectionMode { mode }

    private func redraw() { overlayViews.forEach { $0.needsDisplay = true; $0.updateControls() } }

    private func finish(_ outcome: SelectionOutcome?) {
        guard !completed else { return }
        completed = true
        NSCursor.pop()
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()
        overlayViews.removeAll()
        completion(outcome)
    }
}

private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

private enum RegionInteraction {
    case idle
    case dragging(start: CGPoint)
    case moving(last: CGPoint)
    case resizing(SelectionHandle)
    case editing
}

final class SelectionOverlayView: NSView {
    private weak var controller: SelectionOverlayController?
    private let screen: NSScreen
    private var selection: SelectionModel
    private var interaction: RegionInteraction = .idle
    private let toolbar = MaterialCardView(frame: CGRect(x: 0, y: 0, width: 212, height: 44))
    private let sizeLabel = PillLabel()
    private let loupe = SelectionLoupeView(frame: CGRect(x: 0, y: 0, width: 120, height: 86))

    init(screen: NSScreen, controller: SelectionOverlayController) {
        self.screen = screen
        self.controller = controller
        selection = SelectionModel(bounds: CGRect(origin: .zero, size: screen.frame.size))
        super.init(frame: CGRect(origin: .zero, size: screen.frame.size))
        wantsLayer = true
        buildToolbar()
        addSubview(sizeLabel)
        addSubview(loupe)
        toolbar.isHidden = true
        sizeLabel.isHidden = true
        loupe.isHidden = true
    }

    required init?(coder: NSCoder) { nil }
    override var acceptsFirstResponder: Bool { true }

    var globalSelectionRect: CGRect? {
        guard let region = selection.region, let window else { return nil }
        return window.convertToScreen(region)
    }

    func clearRegion() {
        selection = SelectionModel(bounds: bounds)
        interaction = .idle
        updateControls()
        needsDisplay = true
    }

    func modeDidChange() {
        interaction = .idle
        updateControls()
        needsDisplay = true
    }

    func nudge(dx: CGFloat, dy: CGFloat, accelerated: Bool) {
        selection.nudge(dx: dx, dy: dy, accelerated: accelerated)
        interaction = .editing
        updateControls()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        SnapSailStyle.overlayDim.setFill()
        bounds.fill()

        if controller?.selectionMode == .region, let region = selection.region {
            NSGraphicsContext.saveGraphicsState()
            NSColor.clear.setFill()
            region.fill(using: .copy)
            NSGraphicsContext.restoreGraphicsState()

            SnapSailStyle.selectionFill.setFill()
            region.fill()
            SnapSailStyle.accent.setStroke()
            let border = NSBezierPath(rect: region.insetBy(dx: 1, dy: 1))
            border.lineWidth = 2
            border.stroke()

            if case .editing = interaction { drawHandles(for: region) }
        } else if let highlights = controller?.highlightRects(for: screen) {
            for (rect, selected) in highlights {
                NSGraphicsContext.saveGraphicsState()
                NSColor.clear.setFill()
                rect.fill(using: .copy)
                NSGraphicsContext.restoreGraphicsState()
                (selected ? NSColor.systemGreen.withAlphaComponent(0.08) : SnapSailStyle.selectionFill).setFill()
                rect.fill()
                (selected ? NSColor.systemGreen : SnapSailStyle.accent).setStroke()
                let path = NSBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), xRadius: 3, yRadius: 3)
                path.lineWidth = 2
                path.stroke()
            }
        }

        drawInstruction()
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard controller?.selectionMode == .region else {
            controller?.windowClicked(from: self, modifiers: event.modifierFlags)
            return
        }

        if let handle = selection.handle(at: point, tolerance: 9) {
            interaction = .resizing(handle)
        } else if selection.region?.contains(point) == true {
            interaction = .moving(last: point)
        } else {
            controller?.regionWillBegin(in: self)
            selection = SelectionModel(bounds: bounds)
            selection.setRegion(CGRect(origin: point, size: CGSize(width: 1, height: 1)))
            interaction = .dragging(start: point)
        }
        loupe.isHidden = false
        updateLoupe(at: point)
        updateControls()
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        switch interaction {
        case .dragging(let start):
            selection.setRegion(CGRect(
                x: min(start.x, point.x), y: min(start.y, point.y),
                width: max(1, abs(point.x - start.x)), height: max(1, abs(point.y - start.y))
            ))
        case .moving(let last):
            selection.move(by: CGSize(width: point.x - last.x, height: point.y - last.y))
            interaction = .moving(last: point)
        case .resizing(let handle):
            selection.resize(handle: handle, to: point)
        default: break
        }
        updateLoupe(at: point)
        updateControls()
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard controller?.selectionMode == .region else { return }
        if let region = selection.region, region.width >= 24, region.height >= 24 {
            interaction = .editing
        } else {
            interaction = .idle
        }
        loupe.isHidden = true
        updateControls()
        needsDisplay = true
    }

    override func mouseMoved(with event: NSEvent) {
        guard let window else { return }
        let local = convert(event.locationInWindow, from: nil)
        controller?.mouseMoved(to: window.convertPoint(toScreen: local), in: self)
        if controller?.selectionMode == .region, selection.region == nil {
            loupe.isHidden = false
            updateLoupe(at: local)
        } else if controller?.selectionMode == .window {
            updateControls()
        }
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: controller?.cancel()
        case 36: controller?.perform(.capture)
        case 49: controller?.toggleMode()
        case 123: controller?.nudgeSelection(dx: -1, dy: 0, accelerated: event.modifierFlags.contains(.shift))
        case 124: controller?.nudgeSelection(dx: 1, dy: 0, accelerated: event.modifierFlags.contains(.shift))
        case 125: controller?.nudgeSelection(dx: 0, dy: -1, accelerated: event.modifierFlags.contains(.shift))
        case 126: controller?.nudgeSelection(dx: 0, dy: 1, accelerated: event.modifierFlags.contains(.shift))
        default: super.keyDown(with: event)
        }
    }

    func updateControls() {
        let target: CGRect?
        if controller?.selectionMode == .region {
            target = selection.region
            let isEditing: Bool
            if case .editing = interaction { isEditing = true } else { isEditing = false }
            toolbar.isHidden = !isEditing
            sizeLabel.isHidden = selection.region == nil
        } else {
            target = controller?.highlightRects(for: screen).last?.0
            toolbar.isHidden = target == nil
            sizeLabel.isHidden = true
        }
        guard let target else { return }

        if controller?.selectionMode == .region {
            sizeLabel.stringValue = "\(Int(target.width)) × \(Int(target.height))"
            let labelWidth = max(74, sizeLabel.intrinsicContentSize.width + 18)
            sizeLabel.frame = CGRect(
                x: min(bounds.maxX - labelWidth - 8, target.minX),
                y: min(bounds.maxY - 26, target.maxY + 7),
                width: labelWidth,
                height: 22
            )
        }

        let toolbarX = min(max(8, target.midX - toolbar.frame.width / 2), bounds.maxX - toolbar.frame.width - 8)
        var toolbarY = target.minY - toolbar.frame.height - 12
        if toolbarY < 8 { toolbarY = min(bounds.maxY - toolbar.frame.height - 8, target.maxY + 12) }
        toolbar.frame.origin = CGPoint(x: toolbarX, y: toolbarY)
    }

    private func buildToolbar() {
        addSubview(toolbar)
        let definitions: [(String, String, Selector)] = [
            ("checkmark", "Capture (Return)", #selector(capture)),
            ("arrow.down.to.line.compact", "Scrolling Capture", #selector(startScrollingCapture)),
            ("doc.on.doc", "Copy to Clipboard", #selector(copyImage)),
            ("pin", "Pin on Screen", #selector(pin)),
            ("xmark", "Cancel (Esc)", #selector(cancel))
        ]
        var x: CGFloat = 10
        for (index, definition) in definitions.enumerated() {
            let button = SymbolButton(symbol: definition.0, toolTip: definition.1, target: self, action: definition.2)
            button.frame.origin = CGPoint(x: x, y: 6)
            if index == 0 { button.isSelected = true }
            toolbar.addSubview(button)
            x += 40
        }
    }

    private func updateLoupe(at point: CGPoint) {
        guard let window, !loupe.isHidden else { return }
        let global = window.convertPoint(toScreen: point)
        loupe.image = controller?.loupeImage(at: global, below: window.windowNumber)
        var x = point.x + 18
        if x + loupe.frame.width > bounds.maxX { x = point.x - loupe.frame.width - 18 }
        var y = point.y - loupe.frame.height - 18
        if y < 8 { y = point.y + 18 }
        loupe.frame.origin = CGPoint(x: x, y: y)
        loupe.needsDisplay = true
    }

    private func drawHandles(for region: CGRect) {
        let points = [
            CGPoint(x: region.minX, y: region.minY), CGPoint(x: region.midX, y: region.minY), CGPoint(x: region.maxX, y: region.minY),
            CGPoint(x: region.maxX, y: region.midY), CGPoint(x: region.maxX, y: region.maxY), CGPoint(x: region.midX, y: region.maxY),
            CGPoint(x: region.minX, y: region.maxY), CGPoint(x: region.minX, y: region.midY)
        ]
        for point in points {
            let rect = CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)
            NSColor.white.setFill()
            NSBezierPath(ovalIn: rect).fill()
            SnapSailStyle.accent.setStroke()
            let outline = NSBezierPath(ovalIn: rect)
            outline.lineWidth = 1.5
            outline.stroke()
        }
    }

    private func drawInstruction() {
        let text = controller?.selectionMode == .window
            ? "Click to select · Shift-click multiple · Space switches mode · Esc cancels"
            : "Drag to select · Move or resize · Return captures · Space switches mode"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let size = text.size(withAttributes: attributes)
        let bubble = CGRect(x: bounds.midX - size.width / 2 - 14, y: bounds.maxY - 48, width: size.width + 28, height: 29)
        NSColor.black.withAlphaComponent(0.68).setFill()
        NSBezierPath(roundedRect: bubble, xRadius: 8, yRadius: 8).fill()
        text.draw(at: CGPoint(x: bubble.minX + 14, y: bubble.minY + 6), withAttributes: attributes)
    }

    @objc private func capture() { controller?.perform(.capture) }
    @objc private func startScrollingCapture() { controller?.perform(.scroll) }
    @objc private func copyImage() { controller?.perform(.copy) }
    @objc private func pin() { controller?.perform(.pin) }
    @objc private func cancel() { controller?.cancel() }
}

private final class SelectionLoupeView: NSView {
    var image: CGImage?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 9
        layer?.borderWidth = 2
        layer?.borderColor = NSColor.white.cgColor
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.28
        layer?.shadowRadius = 8
        layer?.shadowOffset = CGSize(width: 0, height: -3)
    }

    required init?(coder: NSCoder) { nil }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.82).setFill()
        bounds.fill()
        if let image {
            NSGraphicsContext.current?.imageInterpolation = .none
            NSImage(cgImage: image, size: bounds.size).draw(in: bounds.insetBy(dx: 2, dy: 2))
        }
        NSColor.white.withAlphaComponent(0.9).setStroke()
        let cross = NSBezierPath()
        cross.move(to: CGPoint(x: bounds.midX, y: 2))
        cross.line(to: CGPoint(x: bounds.midX, y: bounds.maxY - 2))
        cross.move(to: CGPoint(x: 2, y: bounds.midY))
        cross.line(to: CGPoint(x: bounds.maxX - 2, y: bounds.midY))
        cross.lineWidth = 1
        cross.stroke()
        SnapSailStyle.accent.setStroke()
        NSBezierPath(rect: CGRect(x: bounds.midX - 5, y: bounds.midY - 5, width: 10, height: 10)).stroke()
    }
}
