import CoreGraphics

public enum FrozenCaptureGeometry {
    public static func pixelCropRect(
        appKitRect: CGRect,
        screenFrame: CGRect,
        imagePixelSize: CGSize
    ) -> CGRect? {
        guard screenFrame.width > 0,
              screenFrame.height > 0,
              imagePixelSize.width > 0,
              imagePixelSize.height > 0 else { return nil }

        let clipped = appKitRect.intersection(screenFrame)
        guard !clipped.isNull, clipped.width > 0, clipped.height > 0 else { return nil }

        let scaleX = imagePixelSize.width / screenFrame.width
        let scaleY = imagePixelSize.height / screenFrame.height
        let localMinX = clipped.minX - screenFrame.minX
        let localMaxY = clipped.maxY - screenFrame.minY
        let pixelBounds = CGRect(origin: .zero, size: imagePixelSize)
        let pixelRect = CGRect(
            x: localMinX * scaleX,
            y: (screenFrame.height - localMaxY) * scaleY,
            width: clipped.width * scaleX,
            height: clipped.height * scaleY
        ).integral.intersection(pixelBounds)

        guard !pixelRect.isNull, pixelRect.width > 0, pixelRect.height > 0 else { return nil }
        return pixelRect
    }
}
