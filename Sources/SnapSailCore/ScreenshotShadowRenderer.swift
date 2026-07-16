import CoreGraphics

public enum ScreenshotShadowRenderer {
    public static func render(
        _ source: CGImage,
        padding: Int = 36,
        blur: CGFloat = 18,
        offset: CGSize = CGSize(width: 0, height: -6)
    ) -> CGImage? {
        let safePadding = max(0, padding)
        let width = source.width + safePadding * 2
        let height = source.height + safePadding * 2
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let imageRect = CGRect(
            x: safePadding,
            y: safePadding,
            width: source.width,
            height: source.height
        )
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        context.interpolationQuality = .none
        context.saveGState()
        context.setShadow(
            offset: offset,
            blur: max(0, blur),
            color: CGColor(gray: 0, alpha: 0.32)
        )
        context.draw(source, in: imageRect)
        context.restoreGState()
        context.draw(source, in: imageRect)
        return context.makeImage()
    }
}
