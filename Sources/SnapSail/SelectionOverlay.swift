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
    case save
    case copy
    case pin
}

struct SelectionOutcome {
    let selection: SelectionResult
    let action: SelectionAction
    let annotations: [InlineAnnotation]
    let selectionPointSize: CGSize
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
        NSApplication.shared.activate(ignoringOtherApps: true)
        let mouseLocation = NSEvent.mouseLocation
        var preferredWindow: NSWindow?
        for screen in NSScreen.screens {
            let window = OverlayWindow(
                contentRect: OverlayScreenGeometry.localContentRect(for: screen.frame),
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
            if screen.frame.contains(mouseLocation) { preferredWindow = window }
            window.orderFrontRegardless()
        }
        (preferredWindow ?? overlayWindows.first)?.makeKeyAndOrderFront(nil)
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
            finish(SelectionOutcome(
                selection: .region(globalRect.integral),
                action: action,
                annotations: view.annotationSnapshot,
                selectionPointSize: view.selectionPointSize
            ))
        case .window:
            var selected = availableWindows.filter { selectedWindowIDs.contains($0.id) }
            if selected.isEmpty, let highlightedWindow { selected = [highlightedWindow] }
            guard !selected.isEmpty else { return }
            finish(SelectionOutcome(
                selection: .windows(selected),
                action: action,
                annotations: [],
                selectionPointSize: .zero
            ))
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

    func annotationSourceImage(in appKitRect: CGRect, below windowNumber: Int) -> CGImage? {
        CGWindowListCreateImage(
            captureService.quartzRect(fromAppKitRect: appKitRect).integral,
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
    case annotating
    case editing
}

final class SelectionOverlayView: NSView {
    private weak var controller: SelectionOverlayController?
    private let screen: NSScreen
    private var selection: SelectionModel
    private var interaction: RegionInteraction = .idle
    private let toolbar = InlineCaptureToolbar(frame: CGRect(origin: .zero, size: InlineCaptureToolbar.preferredSize))
    private let pinButton = CircularSymbolButton(symbol: "pin.fill", toolTip: L10n.text(.pinOnScreen), target: nil, action: nil)
    private let sizeLabel = MeasurementPillView(
        frame: CGRect(origin: .zero, size: MeasurementPillView.preferredSize)
    )
    private let loupe = SelectionLoupeView(frame: CGRect(x: 0, y: 0, width: 120, height: 86))
    private var annotationHistory = InlineAnnotationHistory()
    private var annotationDraft: InlineAnnotation?
    private var activeTool: InlineAnnotationTool?
    private var activeColor = InlineAnnotationColor.red
    private var annotationSourceImage: CGImage?
    private var textAnchor: CGPoint?
    private weak var inlineTextField: NSTextField?

    init(screen: NSScreen, controller: SelectionOverlayController) {
        self.screen = screen
        self.controller = controller
        selection = SelectionModel(bounds: CGRect(origin: .zero, size: screen.frame.size))
        super.init(frame: CGRect(origin: .zero, size: screen.frame.size))
        wantsLayer = true
        configureToolbar()
        addSubview(sizeLabel)
        addSubview(pinButton)
        addSubview(loupe)
        toolbar.isHidden = true
        pinButton.isHidden = true
        sizeLabel.isHidden = true
        loupe.isHidden = true
    }

    required init?(coder: NSCoder) { nil }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    var globalSelectionRect: CGRect? {
        guard let region = selection.region, let window else { return nil }
        return window.convertToScreen(region)
    }

    var annotationSnapshot: [InlineAnnotation] { annotationHistory.annotations }
    var selectionPointSize: CGSize { selection.region?.size ?? .zero }

    func clearRegion() {
        selection = SelectionModel(bounds: bounds)
        annotationHistory.removeAll()
        annotationDraft = nil
        annotationSourceImage = nil
        activeTool = nil
        toolbar.clearActiveTool()
        interaction = .idle
        updateControls()
        needsDisplay = true
    }

    func modeDidChange() {
        annotationDraft = nil
        annotationSourceImage = nil
        interaction = .idle
        updateControls()
        needsDisplay = true
    }

    func nudge(dx: CGFloat, dy: CGFloat, accelerated: Bool) {
        selection.nudge(dx: dx, dy: dy, accelerated: accelerated)
        refreshAnnotationSourceImage()
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
            let border = NSBezierPath(rect: region.insetBy(dx: 1, dy: 1))
            for (width, alpha) in [(CGFloat(14), CGFloat(0.11)), (CGFloat(7), CGFloat(0.24))] {
                SnapSailStyle.accent.withAlphaComponent(alpha).setStroke()
                border.lineWidth = width
                border.stroke()
            }
            SnapSailStyle.accent.setStroke()
            border.lineWidth = 2
            NSGraphicsContext.saveGraphicsState()
            let shadow = NSShadow()
            shadow.shadowColor = SnapSailStyle.accent.withAlphaComponent(0.58)
            shadow.shadowBlurRadius = 12
            shadow.shadowOffset = .zero
            shadow.set()
            border.stroke()
            NSGraphicsContext.restoreGraphicsState()

            InlineAnnotationRenderer.draw(
                annotations: annotationHistory.annotations,
                draft: annotationDraft,
                in: region,
                sourceImage: annotationSourceImage
            )

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

        if controller?.selectionMode == .window || selection.region == nil {
            drawInstruction()
        }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard controller?.selectionMode == .region else {
            controller?.windowClicked(from: self, modifiers: event.modifierFlags)
            return
        }

        if let tool = activeTool, let region = selection.region, region.contains(point) {
            beginAnnotation(tool: tool, at: point, in: region)
            loupe.isHidden = true
            updateControls()
            needsDisplay = true
            return
        }

        if let handle = selection.handle(at: point, tolerance: 9) {
            interaction = .resizing(handle)
        } else if selection.region?.contains(point) == true {
            interaction = .moving(last: point)
        } else {
            controller?.regionWillBegin(in: self)
            selection = SelectionModel(bounds: bounds)
            annotationHistory.removeAll()
            annotationDraft = nil
            annotationSourceImage = nil
            activeTool = nil
            toolbar.clearActiveTool()
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
        case .annotating:
            updateAnnotation(at: point)
        default: break
        }
        updateLoupe(at: point)
        updateControls()
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard controller?.selectionMode == .region else { return }
        if case .annotating = interaction {
            updateAnnotation(at: convert(event.locationInWindow, from: nil))
            commitDraftIfNeeded()
            interaction = .editing
            updateControls()
            needsDisplay = true
            return
        }
        if let region = selection.region, region.width >= 24, region.height >= 24 {
            refreshAnnotationSourceImage()
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
        if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "z" {
            if event.modifierFlags.contains(.shift) { redoAnnotation() }
            else { undoAnnotation() }
            return
        }
        switch event.keyCode {
        case 53: controller?.cancel()
        case 36: controller?.perform(.copy)
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
            let isReady: Bool
            switch interaction {
            case .editing, .moving, .resizing, .annotating: isReady = true
            default: isReady = false
            }
            toolbar.isHidden = !isReady
            pinButton.isHidden = !isReady
            sizeLabel.isHidden = selection.region == nil
        } else {
            target = controller?.highlightRects(for: screen).last?.0
            toolbar.isHidden = target == nil
            pinButton.isHidden = target == nil
            sizeLabel.isHidden = true
        }
        guard let target else { return }

        if controller?.selectionMode == .region {
            sizeLabel.setSize(target.size)
            let labelSize = MeasurementPillView.preferredSize
            var labelY = target.maxY + 10
            if labelY + labelSize.height > bounds.maxY {
                labelY = target.maxY - labelSize.height - 8
            }
            sizeLabel.frame = CGRect(
                x: min(max(8, target.midX - labelSize.width / 2), bounds.maxX - labelSize.width - 8),
                y: labelY,
                width: labelSize.width,
                height: labelSize.height
            )
        }

        let maximumToolbarX = max(12, bounds.maxX - toolbar.frame.width - 12)
        let toolbarX = min(max(12, target.midX - toolbar.frame.width / 2), maximumToolbarX)
        var toolbarY = target.minY - toolbar.frame.height - 34
        if toolbarY < 12 {
            toolbarY = min(bounds.maxY - toolbar.frame.height - 12, target.maxY + 74)
        }
        toolbar.frame.origin = CGPoint(x: toolbarX, y: toolbarY)

        var pinX = target.maxX + 16
        if pinX + pinButton.frame.width > bounds.maxX - 8 { pinX = target.maxX - pinButton.frame.width - 12 }
        var pinY = target.maxY - pinButton.frame.height
        if pinY < 8 { pinY = target.minY + 8 }
        pinButton.frame.origin = CGPoint(x: pinX, y: pinY)
        toolbar.updateHistory(canUndo: annotationHistory.canUndo, canRedo: annotationHistory.canRedo)
    }

    private func configureToolbar() {
        addSubview(toolbar)
        toolbar.onToolSelected = { [weak self] tool in
            self?.activeTool = tool
            if tool == .pixelate, self?.annotationSourceImage == nil {
                self?.refreshAnnotationSourceImage()
            }
            NSCursor.crosshair.set()
        }
        toolbar.onColorChanged = { [weak self] color in self?.activeColor = color }
        toolbar.onUndo = { [weak self] in self?.undoAnnotation() }
        toolbar.onRedo = { [weak self] in self?.redoAnnotation() }
        toolbar.onCancel = { [weak self] in self?.controller?.cancel() }
        toolbar.onScroll = { [weak self] in self?.controller?.perform(.scroll) }
        toolbar.onSave = { [weak self] in self?.controller?.perform(.save) }
        toolbar.onCopy = { [weak self] in self?.controller?.perform(.copy) }
        pinButton.target = self
        pinButton.action = #selector(pin)
    }

    private func beginAnnotation(tool: InlineAnnotationTool, at point: CGPoint, in region: CGRect) {
        let normalized = InlineAnnotation.normalizedPoint(point, in: region)
        if tool == .number {
            let nextNumber = annotationHistory.annotations.filter { $0.tool == .number }.count + 1
            annotationHistory.commit(InlineAnnotation(
                tool: .number,
                start: normalized,
                end: normalized,
                number: nextNumber,
                color: activeColor
            ))
            interaction = .editing
            return
        }
        if tool == .text {
            beginTextEditing(at: point, normalized: normalized)
            interaction = .editing
            return
        }
        annotationDraft = InlineAnnotation(
            tool: tool,
            start: normalized,
            end: normalized,
            points: tool == .pen || tool == .highlight ? [normalized] : [],
            color: activeColor
        )
        interaction = .annotating
    }

    private func updateAnnotation(at point: CGPoint) {
        guard let region = selection.region, var draft = annotationDraft else { return }
        let normalized = InlineAnnotation.normalizedPoint(point, in: region)
        draft.end = normalized
        if draft.tool == .pen || draft.tool == .highlight { draft.points.append(normalized) }
        annotationDraft = draft
    }

    private func commitDraftIfNeeded() {
        guard let draft = annotationDraft, let region = selection.region else { return }
        annotationDraft = nil
        let distance = hypot(
            (draft.end.x - draft.start.x) * region.width,
            (draft.end.y - draft.start.y) * region.height
        )
        guard distance >= 3 || draft.points.count > 2 else { return }
        annotationHistory.commit(draft)
    }

    private func beginTextEditing(at point: CGPoint, normalized: CGPoint) {
        inlineTextField?.removeFromSuperview()
        textAnchor = normalized
        let width = min(220, max(100, bounds.maxX - point.x - 12))
        let field = NSTextField(frame: CGRect(x: point.x, y: point.y - 15, width: width, height: 30))
        field.placeholderString = L10n.text(.typeAndReturn)
        field.font = .systemFont(ofSize: 16, weight: .semibold)
        field.focusRingType = .none
        field.wantsLayer = true
        field.layer?.cornerRadius = 6
        field.layer?.borderColor = SnapSailStyle.accent.cgColor
        field.layer?.borderWidth = 2
        field.target = self
        field.action = #selector(commitInlineText(_:))
        addSubview(field)
        inlineTextField = field
        window?.makeFirstResponder(field)
    }

    @objc private func commitInlineText(_ sender: NSTextField) {
        defer {
            sender.removeFromSuperview()
            textAnchor = nil
            window?.makeFirstResponder(self)
            updateControls()
            needsDisplay = true
        }
        guard let textAnchor, !sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        annotationHistory.commit(InlineAnnotation(
            tool: .text,
            start: textAnchor,
            end: textAnchor,
            text: sender.stringValue,
            color: activeColor
        ))
    }

    private func undoAnnotation() {
        annotationHistory.undo()
        updateControls()
        needsDisplay = true
    }

    private func redoAnnotation() {
        annotationHistory.redo()
        updateControls()
        needsDisplay = true
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

    private func refreshAnnotationSourceImage() {
        guard let controller,
              let window,
              let region = selection.region else {
            annotationSourceImage = nil
            return
        }
        annotationSourceImage = controller.annotationSourceImage(
            in: window.convertToScreen(region),
            below: window.windowNumber
        )
    }

    private func drawHandles(for region: CGRect) {
        let length: CGFloat = min(38, max(14, min(region.width, region.height) * 0.12))
        let corners: [(CGPoint, CGFloat, CGFloat)] = [
            (CGPoint(x: region.minX, y: region.minY), 1, 1),
            (CGPoint(x: region.maxX, y: region.minY), -1, 1),
            (CGPoint(x: region.maxX, y: region.maxY), -1, -1),
            (CGPoint(x: region.minX, y: region.maxY), 1, -1)
        ]
        SnapSailStyle.accent.setStroke()
        for (point, horizontalDirection, verticalDirection) in corners {
            let path = NSBezierPath()
            path.move(to: CGPoint(x: point.x + horizontalDirection * length, y: point.y))
            path.line(to: point)
            path.line(to: CGPoint(x: point.x, y: point.y + verticalDirection * length))
            path.lineWidth = 4
            path.lineCapStyle = .square
            path.stroke()
        }

        let edgePoints = [
            CGPoint(x: region.midX, y: region.minY), CGPoint(x: region.maxX, y: region.midY),
            CGPoint(x: region.midX, y: region.maxY), CGPoint(x: region.minX, y: region.midY)
        ]
        for point in edgePoints {
            NSColor.white.setFill()
            let handle = CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)
            handle.fill()
            SnapSailStyle.accent.setStroke()
            NSBezierPath(rect: handle).stroke()
        }
    }

    private func drawInstruction() {
        let text = controller?.selectionMode == .window
            ? L10n.text(.windowInstruction)
            : L10n.text(.regionInstruction)
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

    @objc private func pin() { controller?.perform(.pin) }
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
