import AppKit
import SnapSailCore

enum InlineAnnotationRenderer {
    static func draw(
        annotations: [InlineAnnotation],
        draft: InlineAnnotation?,
        in selection: CGRect,
        sourceImage: CGImage? = nil
    ) {
        let previewSource = sourceImage.map { NSImage(cgImage: $0, size: selection.size) }
        for annotation in annotations {
            draw(annotation, in: selection, lineScale: 1, sourceImage: previewSource)
        }
        if let draft {
            draw(draft, in: selection, lineScale: 1, sourceImage: previewSource)
        }
    }

    static func render(
        base: CGImage,
        annotations: [InlineAnnotation],
        selectionPointSize: CGSize
    ) -> CGImage? {
        InlineAnnotationRasterizer.render(
            base: base,
            annotations: annotations,
            selectionPointSize: selectionPointSize
        )
    }

    private static func draw(
        _ annotation: InlineAnnotation,
        in rect: CGRect,
        lineScale: CGFloat,
        sourceImage: NSImage?
    ) {
        let start = point(annotation.start, in: rect)
        let end = point(annotation.end, in: rect)
        let shapeRect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        let color = NSColor(
            calibratedRed: annotation.color.red,
            green: annotation.color.green,
            blue: annotation.color.blue,
            alpha: annotation.color.alpha
        )
        let width = max(1.5, annotation.lineWidth * lineScale)

        color.setStroke()
        color.setFill()

        switch annotation.tool {
        case .rectangle:
            let path = NSBezierPath(roundedRect: shapeRect, xRadius: width, yRadius: width)
            path.lineWidth = width
            path.stroke()
        case .ellipse:
            let path = NSBezierPath(ovalIn: shapeRect)
            path.lineWidth = width
            path.stroke()
        case .line, .arrow:
            let path = NSBezierPath()
            path.move(to: start)
            path.line(to: end)
            path.lineWidth = width
            path.lineCapStyle = .round
            path.stroke()
            if annotation.tool == .arrow {
                drawArrowHead(from: start, to: end, width: width, color: color)
            }
        case .pen, .highlight:
            guard let first = annotation.points.first else { return }
            let path = NSBezierPath()
            path.move(to: point(first, in: rect))
            for item in annotation.points.dropFirst() {
                path.line(to: point(item, in: rect))
            }
            let strokeColor = annotation.tool == .highlight ? color.withAlphaComponent(0.34) : color
            strokeColor.setStroke()
            path.lineWidth = annotation.tool == .highlight ? width * 5 : width
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.stroke()
        case .pixelate:
            if let sourceImage, shapeRect.width >= 2, shapeRect.height >= 2 {
                drawPixelation(
                    of: sourceImage,
                    in: shapeRect,
                    sourceRect: shapeRect.offsetBy(dx: -rect.minX, dy: -rect.minY)
                )
            } else {
                drawPixelationPlaceholder(in: shapeRect)
            }
        case .text:
            let fontSize = max(15, 18 * lineScale)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
                .foregroundColor: color,
                .strokeColor: NSColor.white.withAlphaComponent(0.8),
                .strokeWidth: -1.2
            ]
            annotation.text.draw(at: start, withAttributes: attributes)
        case .number:
            let diameter = max(22, 24 * lineScale)
            let markerRect = CGRect(
                x: start.x - diameter / 2,
                y: start.y - diameter / 2,
                width: diameter,
                height: diameter
            )
            color.setFill()
            NSBezierPath(ovalIn: markerRect).fill()
            let string = "\(max(1, annotation.number))"
            let font = NSFont.monospacedDigitSystemFont(ofSize: diameter * 0.55, weight: .bold)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white
            ]
            let size = string.size(withAttributes: attributes)
            string.draw(
                at: CGPoint(x: markerRect.midX - size.width / 2, y: markerRect.midY - size.height / 2),
                withAttributes: attributes
            )
        }
    }

    private static func point(_ normalized: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + normalized.x * rect.width,
            y: rect.minY + normalized.y * rect.height
        )
    }

    private static func drawArrowHead(from start: CGPoint, to end: CGPoint, width: CGFloat, color: NSColor) {
        let angle = atan2(end.y - start.y, end.x - start.x)
        let length = max(12, width * 4.2)
        let wing = CGFloat.pi / 6
        let path = NSBezierPath()
        path.move(to: end)
        path.line(to: CGPoint(x: end.x - length * cos(angle - wing), y: end.y - length * sin(angle - wing)))
        path.move(to: end)
        path.line(to: CGPoint(x: end.x - length * cos(angle + wing), y: end.y - length * sin(angle + wing)))
        path.lineWidth = width
        path.lineCapStyle = .round
        color.setStroke()
        path.stroke()
    }

    private static func drawPixelationPlaceholder(in rect: CGRect) {
        let blockSize: CGFloat = 10
        var row = 0
        var y = rect.minY
        while y < rect.maxY {
            var column = 0
            var x = rect.minX
            while x < rect.maxX {
                let shade: CGFloat = (row + column).isMultiple(of: 2) ? 0.38 : 0.52
                NSColor(white: shade, alpha: 0.88).setFill()
                CGRect(
                    x: x,
                    y: y,
                    width: min(blockSize, rect.maxX - x),
                    height: min(blockSize, rect.maxY - y)
                ).fill()
                x += blockSize
                column += 1
            }
            y += blockSize
            row += 1
        }
    }

    private static func drawPixelation(of source: NSImage, in rect: CGRect, sourceRect: CGRect) {
        let blockSize: CGFloat = 12
        let reducedSize = NSSize(
            width: max(1, ceil(rect.width / blockSize)),
            height: max(1, ceil(rect.height / blockSize))
        )
        let reduced = NSImage(size: reducedSize)
        reduced.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .low
        source.draw(
            in: CGRect(origin: .zero, size: reducedSize),
            from: sourceRect,
            operation: .copy,
            fraction: 1
        )
        reduced.unlockFocus()
        NSGraphicsContext.current?.imageInterpolation = .none
        reduced.draw(in: rect, from: .zero, operation: .copy, fraction: 1)
    }
}
