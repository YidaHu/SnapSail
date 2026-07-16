import CoreGraphics

public enum InlineAnnotationTool: Int, CaseIterable, Equatable {
    case rectangle
    case ellipse
    case line
    case arrow
    case pen
    case pixelate
    case text
    case number
    case highlight
}

public struct InlineAnnotationColor: Equatable {
    public let red: CGFloat
    public let green: CGFloat
    public let blue: CGFloat
    public let alpha: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public static let red = InlineAnnotationColor(red: 0.96, green: 0.16, blue: 0.18)
}

public struct InlineAnnotation: Equatable {
    public let tool: InlineAnnotationTool
    public var start: CGPoint
    public var end: CGPoint
    public var points: [CGPoint]
    public var text: String
    public var number: Int
    public var color: InlineAnnotationColor
    public var lineWidth: CGFloat

    public init(
        tool: InlineAnnotationTool,
        start: CGPoint,
        end: CGPoint,
        points: [CGPoint] = [],
        text: String = "",
        number: Int = 0,
        color: InlineAnnotationColor = .red,
        lineWidth: CGFloat = 3
    ) {
        self.tool = tool
        self.start = start
        self.end = end
        self.points = points
        self.text = text
        self.number = number
        self.color = color
        self.lineWidth = lineWidth
    }

    public static func normalizedPoint(_ point: CGPoint, in selection: CGRect) -> CGPoint {
        guard selection.width > 0, selection.height > 0 else { return .zero }
        return CGPoint(
            x: min(1, max(0, (point.x - selection.minX) / selection.width)),
            y: min(1, max(0, (point.y - selection.minY) / selection.height))
        )
    }
}

public struct InlineAnnotationHistory {
    public private(set) var annotations: [InlineAnnotation] = []
    private var redoAnnotations: [InlineAnnotation] = []

    public init() {}

    public var canUndo: Bool { !annotations.isEmpty }
    public var canRedo: Bool { !redoAnnotations.isEmpty }

    public mutating func commit(_ annotation: InlineAnnotation) {
        annotations.append(annotation)
        redoAnnotations.removeAll()
    }

    public mutating func undo() {
        guard let annotation = annotations.popLast() else { return }
        redoAnnotations.append(annotation)
    }

    public mutating func redo() {
        guard let annotation = redoAnnotations.popLast() else { return }
        annotations.append(annotation)
    }

    public mutating func removeAll() {
        annotations.removeAll()
        redoAnnotations.removeAll()
    }
}
