import CoreGraphics

public enum CaptureGeometry {
    public static func quartzRect(
        fromAppKitRect rect: CGRect,
        primaryScreenHeight: CGFloat
    ) -> CGRect {
        CGRect(
            x: rect.minX,
            y: primaryScreenHeight - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    public static func appKitRect(
        fromQuartzRect rect: CGRect,
        primaryScreenHeight: CGFloat
    ) -> CGRect {
        CGRect(
            x: rect.minX,
            y: primaryScreenHeight - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    public static func sourceRect(
        globalSelection: CGRect,
        displayFrame: CGRect
    ) -> CGRect {
        let clipped = globalSelection.standardized.intersection(displayFrame)
        guard !clipped.isNull, !clipped.isEmpty else { return .zero }

        return CGRect(
            x: clipped.minX - displayFrame.minX,
            y: displayFrame.maxY - clipped.maxY,
            width: clipped.width,
            height: clipped.height
        )
    }
}
