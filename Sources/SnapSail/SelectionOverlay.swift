import AppKit

enum SelectionMode {
    case region
    case window
}

enum SelectionResult {
    case region(CGRect)
    case windows([WindowDescriptor])
}

final class SelectionOverlayController: NSObject {
    private let mode: SelectionMode
    private let captureService: CaptureService
    private let completion: (SelectionResult?) -> Void
    private var overlayWindows: [NSWindow] = []
    private var availableWindows: [WindowDescriptor] = []
    private var highlightedWindow: WindowDescriptor?
    private var selectedWindowIDs = Set<CGWindowID>()
    private var completed = false

    init(mode: SelectionMode, captureService: CaptureService, completion: @escaping (SelectionResult?) -> Void) {
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
            window.contentView = SelectionOverlayView(screen: screen, controller: self)
            window.acceptsMouseMovedEvents = true
            overlayWindows.append(window)
            window.orderFrontRegardless()
        }
        overlayWindows.first?.makeKey()
        NSCursor.crosshair.push()
    }

    func cancel() { finish(nil) }

    func regionDidFinish(_ rect: CGRect) {
        guard rect.width >= 3, rect.height >= 3 else { return cancel() }
        finish(.region(rect.integral))
    }

    func mouseMoved(to globalPoint: CGPoint) {
        guard mode == .window else { return }
        highlightedWindow = captureService.window(atAppKitPoint: globalPoint, in: availableWindows)
        redraw()
    }

    func windowClicked(modifiers: NSEvent.ModifierFlags) {
        guard let highlightedWindow else { return }
        if modifiers.contains(.shift) {
            if selectedWindowIDs.contains(highlightedWindow.id) {
                selectedWindowIDs.remove(highlightedWindow.id)
            } else {
                selectedWindowIDs.insert(highlightedWindow.id)
            }
            redraw()
        } else {
            finish(.windows([highlightedWindow]))
        }
    }

    func finishWindowSelection() {
        let selected = availableWindows.filter { selectedWindowIDs.contains($0.id) }
        guard !selected.isEmpty else { return }
        finish(.windows(selected))
    }

    func highlightRects(for screen: NSScreen) -> [(CGRect, Bool)] {
        var result: [(CGRect, Bool)] = []
        for descriptor in availableWindows {
            let isHighlighted = descriptor.id == highlightedWindow?.id
            let isSelected = selectedWindowIDs.contains(descriptor.id)
            guard isHighlighted || isSelected else { continue }
            let global = descriptor.appKitBounds(primaryScreenHeight: captureService.primaryScreenHeight)
            let local = CGRect(
                x: global.minX - screen.frame.minX,
                y: global.minY - screen.frame.minY,
                width: global.width,
                height: global.height
            )
            result.append((local, isSelected))
        }
        return result
    }

    private func redraw() {
        overlayWindows.forEach { $0.contentView?.needsDisplay = true }
    }

    private func finish(_ result: SelectionResult?) {
        guard !completed else { return }
        completed = true
        NSCursor.pop()
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()
        completion(result)
    }

    fileprivate var selectionMode: SelectionMode { mode }
}

private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

private final class SelectionOverlayView: NSView {
    private weak var controller: SelectionOverlayController?
    private let screen: NSScreen
    private var dragStart: CGPoint?
    private var selectionRect: CGRect?

    init(screen: NSScreen, controller: SelectionOverlayController) {
        self.screen = screen
        self.controller = controller
        super.init(frame: CGRect(origin: .zero, size: screen.frame.size))
    }

    required init?(coder: NSCoder) { nil }
    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.34).setFill()
        bounds.fill()

        if controller?.selectionMode == .region, let selectionRect {
            NSGraphicsContext.saveGraphicsState()
            NSColor.clear.setFill()
            selectionRect.fill(using: .copy)
            NSGraphicsContext.restoreGraphicsState()
            drawBorder(selectionRect, selected: true)
            drawSizeLabel(selectionRect)
        } else if let highlights = controller?.highlightRects(for: screen) {
            for (rect, selected) in highlights {
                NSGraphicsContext.saveGraphicsState()
                NSColor.clear.setFill()
                rect.fill(using: .copy)
                NSGraphicsContext.restoreGraphicsState()
                drawBorder(rect, selected: selected)
            }
        }

        let instruction = controller?.selectionMode == .window
            ? "Click a window · Shift-click to select multiple · Return to finish · Esc to cancel"
            : "Drag to select an area · Esc to cancel"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let size = instruction.size(withAttributes: attributes)
        let bubble = CGRect(x: bounds.midX - size.width / 2 - 14, y: bounds.maxY - 50, width: size.width + 28, height: 30)
        NSColor.black.withAlphaComponent(0.72).setFill()
        NSBezierPath(roundedRect: bubble, xRadius: 8, yRadius: 8).fill()
        instruction.draw(at: CGPoint(x: bubble.minX + 14, y: bubble.minY + 7), withAttributes: attributes)
    }

    override func mouseDown(with event: NSEvent) {
        if controller?.selectionMode == .window {
            controller?.windowClicked(modifiers: event.modifierFlags)
            return
        }
        dragStart = convert(event.locationInWindow, from: nil)
        selectionRect = CGRect(origin: dragStart!, size: .zero)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let dragStart else { return }
        let point = convert(event.locationInWindow, from: nil)
        selectionRect = CGRect(
            x: min(dragStart.x, point.x),
            y: min(dragStart.y, point.y),
            width: abs(point.x - dragStart.x),
            height: abs(point.y - dragStart.y)
        )
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let selectionRect, let window else { return }
        controller?.regionDidFinish(window.convertToScreen(selectionRect))
    }

    override func mouseMoved(with event: NSEvent) {
        guard let window else { return }
        let local = convert(event.locationInWindow, from: nil)
        controller?.mouseMoved(to: window.convertPoint(toScreen: local))
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            controller?.cancel()
        } else if event.keyCode == 36 {
            controller?.finishWindowSelection()
        } else {
            super.keyDown(with: event)
        }
    }

    private func drawBorder(_ rect: CGRect, selected: Bool) {
        (selected ? NSColor.systemGreen : NSColor.systemBlue).setStroke()
        let path = NSBezierPath(rect: rect.insetBy(dx: 1, dy: 1))
        path.lineWidth = selected ? 3 : 2
        path.stroke()
    }

    private func drawSizeLabel(_ rect: CGRect) {
        let text = "\(Int(rect.width)) × \(Int(rect.height))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let size = text.size(withAttributes: attributes)
        let box = CGRect(x: rect.minX, y: min(bounds.maxY - 26, rect.maxY + 6), width: size.width + 12, height: 22)
        NSColor.systemBlue.setFill()
        NSBezierPath(roundedRect: box, xRadius: 5, yRadius: 5).fill()
        text.draw(at: CGPoint(x: box.minX + 6, y: box.minY + 4), withAttributes: attributes)
    }
}
