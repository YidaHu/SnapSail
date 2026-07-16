import CoreGraphics

public enum SelectionHandle: CaseIterable, Equatable {
    case topLeft, top, topRight
    case right
    case bottomRight, bottom, bottomLeft
    case left
}

public struct SelectionModel {
    public let bounds: CGRect
    public let minimumSize: CGFloat
    public private(set) var region: CGRect?

    public init(bounds: CGRect, minimumSize: CGFloat = 24) {
        self.bounds = bounds.standardized
        self.minimumSize = minimumSize
    }

    public mutating func setRegion(_ proposed: CGRect) {
        let clipped = proposed.standardized.intersection(bounds)
        region = clipped.isNull || clipped.isEmpty ? nil : clipped
    }

    public mutating func move(by delta: CGSize) {
        guard var region else { return }
        region.origin.x = min(max(bounds.minX, region.minX + delta.width), bounds.maxX - region.width)
        region.origin.y = min(max(bounds.minY, region.minY + delta.height), bounds.maxY - region.height)
        self.region = region
    }

    public mutating func nudge(dx: CGFloat, dy: CGFloat, accelerated: Bool) {
        let amount: CGFloat = accelerated ? 10 : 1
        move(by: CGSize(width: dx * amount, height: dy * amount))
    }

    public mutating func resize(handle: SelectionHandle, to point: CGPoint) {
        guard let region else { return }
        var minX = region.minX
        var maxX = region.maxX
        var minY = region.minY
        var maxY = region.maxY

        if [.topLeft, .left, .bottomLeft].contains(handle) {
            minX = min(max(bounds.minX, point.x), maxX - minimumSize)
        }
        if [.topRight, .right, .bottomRight].contains(handle) {
            maxX = max(min(bounds.maxX, point.x), minX + minimumSize)
        }
        if [.bottomLeft, .bottom, .bottomRight].contains(handle) {
            minY = min(max(bounds.minY, point.y), maxY - minimumSize)
        }
        if [.topLeft, .top, .topRight].contains(handle) {
            maxY = max(min(bounds.maxY, point.y), minY + minimumSize)
        }

        self.region = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    public func handle(at point: CGPoint, tolerance: CGFloat) -> SelectionHandle? {
        guard let region else { return nil }
        let locations: [(SelectionHandle, CGPoint)] = [
            (.topLeft, CGPoint(x: region.minX, y: region.maxY)),
            (.top, CGPoint(x: region.midX, y: region.maxY)),
            (.topRight, CGPoint(x: region.maxX, y: region.maxY)),
            (.right, CGPoint(x: region.maxX, y: region.midY)),
            (.bottomRight, CGPoint(x: region.maxX, y: region.minY)),
            (.bottom, CGPoint(x: region.midX, y: region.minY)),
            (.bottomLeft, CGPoint(x: region.minX, y: region.minY)),
            (.left, CGPoint(x: region.minX, y: region.midY))
        ]
        return locations.first {
            abs($0.1.x - point.x) <= tolerance && abs($0.1.y - point.y) <= tolerance
        }?.0
    }
}
