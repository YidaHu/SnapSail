import CoreGraphics

public enum OverlayScreenGeometry {
    public static func localContentRect(for screenFrame: CGRect) -> CGRect {
        CGRect(origin: .zero, size: screenFrame.size)
    }
}
