import AppKit
import CoreGraphics
import SnapSailCore

struct WindowDescriptor {
    let id: CGWindowID
    let ownerName: String
    let title: String
    let quartzBounds: CGRect

    func appKitBounds(primaryScreenHeight: CGFloat) -> CGRect {
        CaptureGeometry.appKitRect(
            fromQuartzRect: quartzBounds,
            primaryScreenHeight: primaryScreenHeight
        )
    }
}

struct FrozenScreenCapture {
    let appKitFrame: CGRect
    let image: CGImage

    func image(in appKitRect: CGRect) -> CGImage? {
        guard let pixelRect = FrozenCaptureGeometry.pixelCropRect(
            appKitRect: appKitRect,
            screenFrame: appKitFrame,
            imagePixelSize: CGSize(width: image.width, height: image.height)
        ) else { return nil }
        return image.cropping(to: pixelRect)
    }
}

struct FrozenDesktopCapture {
    let screens: [FrozenScreenCapture]

    func screen(matching appKitFrame: CGRect) -> FrozenScreenCapture? {
        screens.first { $0.appKitFrame == appKitFrame }
    }

    func image(in appKitRect: CGRect) -> CGImage? {
        let midpoint = CGPoint(x: appKitRect.midX, y: appKitRect.midY)
        let screen = screens.first { $0.appKitFrame.contains(midpoint) }
            ?? screens.max {
                intersectionArea($0.appKitFrame, appKitRect) < intersectionArea($1.appKitFrame, appKitRect)
            }
        return screen?.image(in: appKitRect)
    }

    private func intersectionArea(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let intersection = lhs.intersection(rhs)
        guard !intersection.isNull else { return 0 }
        return intersection.width * intersection.height
    }
}

final class CaptureService {
    var primaryScreenHeight: CGFloat {
        NSScreen.screens.first(where: { $0.frame.origin == .zero })?.frame.height
            ?? NSScreen.main?.frame.height
            ?? 0
    }

    func hasPermission() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    @discardableResult
    func requestPermission() -> Bool {
        CGRequestScreenCaptureAccess()
    }

    func quartzRect(fromAppKitRect rect: CGRect) -> CGRect {
        CaptureGeometry.quartzRect(
            fromAppKitRect: rect,
            primaryScreenHeight: primaryScreenHeight
        )
    }

    func appKitRect(fromQuartzRect rect: CGRect) -> CGRect {
        CaptureGeometry.appKitRect(
            fromQuartzRect: rect,
            primaryScreenHeight: primaryScreenHeight
        )
    }

    func capture(appKitRect: CGRect) -> CGImage? {
        capture(quartzRect: quartzRect(fromAppKitRect: appKitRect))
    }

    func capture(quartzRect: CGRect) -> CGImage? {
        CGWindowListCreateImage(
            quartzRect.integral,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution]
        )
    }

    func capture(window: WindowDescriptor, includeShadow: Bool) -> CGImage? {
        var options: CGWindowImageOption = [.bestResolution]
        if !includeShadow { options.insert(.boundsIgnoreFraming) }
        return CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            window.id,
            options
        )
    }

    func freezeDesktop() -> FrozenDesktopCapture? {
        let displays = NSScreen.screens
        guard !displays.isEmpty else { return nil }

        var screens: [FrozenScreenCapture] = []
        screens.reserveCapacity(displays.count)
        for display in displays {
            guard let image = capture(appKitRect: display.frame) else { return nil }
            screens.append(FrozenScreenCapture(appKitFrame: display.frame, image: image))
        }
        return FrozenDesktopCapture(screens: screens)
    }

    func windows() -> [WindowDescriptor] {
        guard let raw = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else { return [] }

        let ownPID = ProcessInfo.processInfo.processIdentifier
        return raw.compactMap { info in
            guard let number = info[kCGWindowNumber as String] as? NSNumber,
                  let ownerPID = info[kCGWindowOwnerPID as String] as? NSNumber,
                  ownerPID.int32Value != ownPID,
                  let layer = info[kCGWindowLayer as String] as? NSNumber,
                  layer.intValue == 0,
                  let boundsDictionary = info[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: boundsDictionary),
                  bounds.width >= 40,
                  bounds.height >= 30 else { return nil }

            return WindowDescriptor(
                id: CGWindowID(number.uint32Value),
                ownerName: info[kCGWindowOwnerName as String] as? String ?? "App",
                title: info[kCGWindowName as String] as? String ?? "",
                quartzBounds: bounds
            )
        }
    }

    func window(atAppKitPoint point: CGPoint, in windows: [WindowDescriptor]) -> WindowDescriptor? {
        let quartzPoint = CGPoint(x: point.x, y: primaryScreenHeight - point.y)
        return windows.first(where: { $0.quartzBounds.contains(quartzPoint) })
    }
}
