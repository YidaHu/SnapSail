import CoreGraphics
import CoreText
import Foundation

public enum InlineAnnotationRasterizer {
    public static func render(
        base: CGImage,
        annotations: [InlineAnnotation],
        selectionPointSize: CGSize
    ) -> CGImage? {
        guard !annotations.isEmpty else { return base }
        guard let context = CGContext(
            data: nil,
            width: base.width,
            height: base.height,
            bitsPerComponent: 8,
            bytesPerRow: base.width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let canvas = CGRect(x: 0, y: 0, width: base.width, height: base.height)
        context.interpolationQuality = .high
        context.draw(base, in: canvas)

        let scaleX = CGFloat(base.width) / max(1, selectionPointSize.width)
        let scaleY = CGFloat(base.height) / max(1, selectionPointSize.height)
        let lineScale = (scaleX + scaleY) / 2
        for annotation in annotations {
            draw(annotation, in: canvas, lineScale: lineScale, base: base, context: context)
        }
        return context.makeImage()
    }

    private static func draw(
        _ annotation: InlineAnnotation,
        in canvas: CGRect,
        lineScale: CGFloat,
        base: CGImage,
        context: CGContext
    ) {
        let start = point(annotation.start, in: canvas)
        let end = point(annotation.end, in: canvas)
        let shape = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        let color = CGColor(
            red: annotation.color.red,
            green: annotation.color.green,
            blue: annotation.color.blue,
            alpha: annotation.color.alpha
        )
        let width = max(1.5, annotation.lineWidth * lineScale)

        context.saveGState()
        defer { context.restoreGState() }
        context.setStrokeColor(color)
        context.setFillColor(color)
        context.setLineWidth(width)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        switch annotation.tool {
        case .rectangle:
            context.stroke(shape)
        case .ellipse:
            context.strokeEllipse(in: shape)
        case .line, .arrow:
            context.move(to: start)
            context.addLine(to: end)
            context.strokePath()
            if annotation.tool == .arrow {
                drawArrowHead(from: start, to: end, width: width, color: color, context: context)
            }
        case .pen, .highlight:
            guard let first = annotation.points.first else { return }
            if annotation.tool == .highlight {
                context.setStrokeColor(color.copy(alpha: 0.34) ?? color)
                context.setLineWidth(width * 5)
            }
            context.move(to: point(first, in: canvas))
            for item in annotation.points.dropFirst() {
                context.addLine(to: point(item, in: canvas))
            }
            context.strokePath()
        case .pixelate:
            drawPixelation(base: base, in: shape, context: context)
        case .text:
            drawText(annotation.text, at: start, color: color, fontSize: max(15, 18 * lineScale), context: context)
        case .number:
            let diameter = max(22, 24 * lineScale)
            let marker = CGRect(
                x: start.x - diameter / 2,
                y: start.y - diameter / 2,
                width: diameter,
                height: diameter
            )
            context.fillEllipse(in: marker)
            drawCenteredText(
                "\(max(1, annotation.number))",
                in: marker,
                color: CGColor(gray: 1, alpha: 1),
                fontSize: diameter * 0.55,
                context: context
            )
        }
    }

    private static func point(_ normalized: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + normalized.x * rect.width, y: rect.minY + normalized.y * rect.height)
    }

    private static func drawArrowHead(
        from start: CGPoint,
        to end: CGPoint,
        width: CGFloat,
        color: CGColor,
        context: CGContext
    ) {
        let angle = atan2(end.y - start.y, end.x - start.x)
        let length = max(12, width * 4.2)
        let wing = CGFloat.pi / 6
        context.setStrokeColor(color)
        context.setLineWidth(width)
        context.move(to: end)
        context.addLine(to: CGPoint(x: end.x - length * cos(angle - wing), y: end.y - length * sin(angle - wing)))
        context.move(to: end)
        context.addLine(to: CGPoint(x: end.x - length * cos(angle + wing), y: end.y - length * sin(angle + wing)))
        context.strokePath()
    }

    private static func drawPixelation(base: CGImage, in rect: CGRect, context: CGContext) {
        guard rect.width >= 2, rect.height >= 2 else { return }
        let cropRect = CGRect(
            x: rect.minX,
            y: CGFloat(base.height) - rect.maxY,
            width: rect.width,
            height: rect.height
        ).integral.intersection(CGRect(x: 0, y: 0, width: base.width, height: base.height))
        guard !cropRect.isNull, let crop = base.cropping(to: cropRect) else { return }
        let blockSize: CGFloat = 12
        let smallWidth = max(1, Int(ceil(rect.width / blockSize)))
        let smallHeight = max(1, Int(ceil(rect.height / blockSize)))
        guard let smallContext = CGContext(
            data: nil,
            width: smallWidth,
            height: smallHeight,
            bitsPerComponent: 8,
            bytesPerRow: smallWidth * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return }
        smallContext.interpolationQuality = .low
        smallContext.draw(crop, in: CGRect(x: 0, y: 0, width: smallWidth, height: smallHeight))
        guard let reduced = smallContext.makeImage() else { return }
        context.interpolationQuality = .none
        context.draw(reduced, in: rect)
    }

    private static func drawText(
        _ text: String,
        at point: CGPoint,
        color: CGColor,
        fontSize: CGFloat,
        context: CGContext
    ) {
        let line = textLine(text, color: color, fontSize: fontSize)
        context.textPosition = point
        CTLineDraw(line, context)
    }

    private static func drawCenteredText(
        _ text: String,
        in rect: CGRect,
        color: CGColor,
        fontSize: CGFloat,
        context: CGContext
    ) {
        let line = textLine(text, color: color, fontSize: fontSize)
        let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
        context.textPosition = CGPoint(
            x: rect.midX - bounds.width / 2 - bounds.minX,
            y: rect.midY - bounds.height / 2 - bounds.minY
        )
        CTLineDraw(line, context)
    }

    private static func textLine(_ text: String, color: CGColor, fontSize: CGFloat) -> CTLine {
        let font = CTFontCreateWithName("HelveticaNeue-Semibold" as CFString, fontSize, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): color
        ]
        return CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
    }
}
