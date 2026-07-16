import AppKit

enum AnnotationTool: Int, CaseIterable {
    case arrow
    case line
    case rectangle
    case ellipse
    case pen
    case text
    case highlight
    case pixelate
    case number

    var title: String {
        switch self {
        case .arrow: return "Arrow"
        case .line: return "Line"
        case .rectangle: return "Rectangle"
        case .ellipse: return "Ellipse"
        case .pen: return "Pen"
        case .text: return "Text"
        case .highlight: return "Highlight"
        case .pixelate: return "Pixelate"
        case .number: return "Number"
        }
    }
}

private struct Annotation {
    let tool: AnnotationTool
    var start: CGPoint
    var end: CGPoint
    var points: [CGPoint]
    var text: String
    var number: Int
    var color: NSColor
    var lineWidth: CGFloat
}

final class AnnotationCanvasView: NSView {
    let sourceImage: CGImage
    var activeTool: AnnotationTool = .arrow
    var activeColor: NSColor = .systemRed
    var activeLineWidth: CGFloat = 4
    var onChange: (() -> Void)?

    private var annotations: [Annotation] = []
    private var redoStack: [Annotation] = []
    private var draft: Annotation?

    init(image: CGImage) {
        sourceImage = image
        super.init(frame: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    }

    required init?(coder: NSCoder) { nil }
    override var acceptsFirstResponder: Bool { true }

    var canUndo: Bool { !annotations.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func undo() {
        guard let item = annotations.popLast() else { return }
        redoStack.append(item)
        needsDisplay = true
        onChange?()
    }

    func redo() {
        guard let item = redoStack.popLast() else { return }
        annotations.append(item)
        needsDisplay = true
        onChange?()
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.controlBackgroundColor.setFill()
        bounds.fill()
        let target = imageRect
        NSGraphicsContext.current?.imageInterpolation = .high
        NSImage(cgImage: sourceImage, size: target.size).draw(in: target)
        for annotation in annotations { draw(annotation, in: target) }
        if let draft { draw(draft, in: target) }
    }

    override func mouseDown(with event: NSEvent) {
        guard let point = imagePoint(for: convert(event.locationInWindow, from: nil)) else { return }
        if activeTool == .number {
            let item = Annotation(
                tool: .number, start: point, end: point, points: [], text: "",
                number: annotations.filter { $0.tool == .number }.count + 1,
                color: activeColor, lineWidth: activeLineWidth
            )
            commit(item)
            return
        }
        draft = Annotation(
            tool: activeTool,
            start: point,
            end: point,
            points: [point],
            text: "",
            number: 0,
            color: activeColor,
            lineWidth: activeLineWidth
        )
    }

    override func mouseDragged(with event: NSEvent) {
        guard var draft,
              let point = imagePoint(for: convert(event.locationInWindow, from: nil)) else { return }
        draft.end = point
        if draft.tool == .pen || draft.tool == .highlight { draft.points.append(point) }
        self.draft = draft
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard var draft else { return }
        if let point = imagePoint(for: convert(event.locationInWindow, from: nil)) { draft.end = point }
        self.draft = nil
        if draft.tool == .text {
            let alert = NSAlert()
            alert.messageText = "Add Text"
            let field = NSTextField(frame: CGRect(x: 0, y: 0, width: 260, height: 24))
            field.placeholderString = "Enter annotation text"
            alert.accessoryView = field
            alert.addButton(withTitle: "Add")
            alert.addButton(withTitle: "Cancel")
            if alert.runModal() == .alertFirstButtonReturn, !field.stringValue.isEmpty {
                draft.text = field.stringValue
                commit(draft)
            }
        } else if hypot(draft.end.x - draft.start.x, draft.end.y - draft.start.y) > 2 {
            commit(draft)
        }
        needsDisplay = true
    }

    func renderedImage() -> CGImage? {
        let size = NSSize(width: sourceImage.width, height: sourceImage.height)
        let image = NSImage(size: size)
        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        NSImage(cgImage: sourceImage, size: size).draw(in: CGRect(origin: .zero, size: size))
        let fullRect = CGRect(origin: .zero, size: size)
        for annotation in annotations { draw(annotation, in: fullRect) }
        image.unlockFocus()
        guard let data = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: data) else { return nil }
        return bitmap.cgImage
    }

    private var imageRect: CGRect {
        let imageSize = CGSize(width: sourceImage.width, height: sourceImage.height)
        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2, width: size.width, height: size.height)
    }

    private func imagePoint(for viewPoint: CGPoint) -> CGPoint? {
        let rect = imageRect
        guard rect.contains(viewPoint) else { return nil }
        return CGPoint(
            x: (viewPoint.x - rect.minX) / rect.width * CGFloat(sourceImage.width),
            y: (viewPoint.y - rect.minY) / rect.height * CGFloat(sourceImage.height)
        )
    }

    private func viewPoint(_ imagePoint: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + imagePoint.x / CGFloat(sourceImage.width) * rect.width,
            y: rect.minY + imagePoint.y / CGFloat(sourceImage.height) * rect.height
        )
    }

    private func commit(_ annotation: Annotation) {
        annotations.append(annotation)
        redoStack.removeAll()
        needsDisplay = true
        onChange?()
    }

    private func draw(_ annotation: Annotation, in rect: CGRect) {
        let start = viewPoint(annotation.start, in: rect)
        let end = viewPoint(annotation.end, in: rect)
        let scale = rect.width / CGFloat(sourceImage.width)
        let width = max(1, annotation.lineWidth * scale)
        annotation.color.setStroke()
        annotation.color.setFill()

        switch annotation.tool {
        case .arrow, .line:
            let path = NSBezierPath()
            path.move(to: start)
            path.line(to: end)
            path.lineWidth = width
            path.lineCapStyle = .round
            path.stroke()
            if annotation.tool == .arrow { drawArrowHead(from: start, to: end, width: width, color: annotation.color) }
        case .rectangle, .ellipse, .pixelate:
            let shapeRect = CGRect(
                x: min(start.x, end.x), y: min(start.y, end.y),
                width: abs(end.x - start.x), height: abs(end.y - start.y)
            )
            if annotation.tool == .pixelate {
                drawPixelation(in: shapeRect)
            } else {
                let path = annotation.tool == .ellipse ? NSBezierPath(ovalIn: shapeRect) : NSBezierPath(rect: shapeRect)
                path.lineWidth = width
                path.stroke()
            }
        case .pen, .highlight:
            let path = NSBezierPath()
            guard let first = annotation.points.first else { return }
            path.move(to: viewPoint(first, in: rect))
            for point in annotation.points.dropFirst() { path.line(to: viewPoint(point, in: rect)) }
            path.lineWidth = annotation.tool == .highlight ? width * 4 : width
            path.lineCapStyle = .round
            (annotation.tool == .highlight ? NSColor.systemYellow.withAlphaComponent(0.45) : annotation.color).setStroke()
            path.stroke()
        case .text:
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: max(14, 24 * scale), weight: .semibold),
                .foregroundColor: annotation.color,
                .strokeColor: NSColor.white,
                .strokeWidth: -2
            ]
            annotation.text.draw(at: start, withAttributes: attributes)
        case .number:
            let radius = max(10, 14 * scale)
            NSBezierPath(ovalIn: CGRect(x: start.x - radius, y: start.y - radius, width: radius * 2, height: radius * 2)).fill()
            let text = "\(annotation.number)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: radius),
                .foregroundColor: NSColor.white
            ]
            let size = text.size(withAttributes: attributes)
            text.draw(at: CGPoint(x: start.x - size.width / 2, y: start.y - size.height / 2), withAttributes: attributes)
        }
    }

    private func drawArrowHead(from start: CGPoint, to end: CGPoint, width: CGFloat, color: NSColor) {
        let angle = atan2(end.y - start.y, end.x - start.x)
        let length = max(12, width * 4)
        let path = NSBezierPath()
        path.move(to: end)
        path.line(to: CGPoint(x: end.x - length * cos(angle - .pi / 6), y: end.y - length * sin(angle - .pi / 6)))
        path.move(to: end)
        path.line(to: CGPoint(x: end.x - length * cos(angle + .pi / 6), y: end.y - length * sin(angle + .pi / 6)))
        path.lineWidth = width
        path.lineCapStyle = .round
        color.setStroke()
        path.stroke()
    }

    private func drawPixelation(in rect: CGRect) {
        NSColor.black.withAlphaComponent(0.72).setFill()
        rect.fill()
        let cell: CGFloat = 8
        NSColor.white.withAlphaComponent(0.12).setFill()
        var y = rect.minY
        var row = 0
        while y < rect.maxY {
            var x = rect.minX + (row % 2 == 0 ? 0 : cell)
            while x < rect.maxX {
                CGRect(x: x, y: y, width: cell, height: cell).intersection(rect).fill()
                x += cell * 2
            }
            y += cell
            row += 1
        }
    }
}
