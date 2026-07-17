import AppKit

enum FrozenBackgroundPainter {
    static func draw(
        _ image: NSImage,
        in bounds: CGRect,
        clippedTo clipRect: CGRect? = nil
    ) {
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }

        if let clipRect {
            NSBezierPath(rect: clipRect).addClip()
        }
        image.draw(
            in: bounds,
            from: .zero,
            operation: .copy,
            fraction: 1,
            respectFlipped: true,
            hints: [.interpolation: NSImageInterpolation.high]
        )
    }
}
