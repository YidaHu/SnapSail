import AppKit
import SnapSailCore

final class ScrollCaptureController: NSObject {
    private let rect: CGRect
    private let captureService: CaptureService
    private let completion: (CGImage?) -> Void
    private let stitcher = ScrollStitcher(
        matcher: VerticalFrameMatcher(
            minimumShift: 3,
            maximumShiftRatio: 0.72,
            sampleStride: 5,
            acceptanceScore: 16
        ),
        maximumHeight: 60_000
    )
    private let processingQueue = DispatchQueue(label: "com.snapsail.scroll-stitching", qos: .userInitiated)
    private var timer: Timer?
    private var panel: NSPanel?
    private var statusLabel: NSTextField?
    private var preview: NSImageView?
    private var isProcessing = false
    private var stopped = false
    private var failures = 0
    private var lastPreviewAt = Date.distantPast

    init(rect: CGRect, captureService: CaptureService, completion: @escaping (CGImage?) -> Void) {
        self.rect = rect
        self.captureService = captureService
        self.completion = completion
    }

    func start() {
        showPanel()
        captureNextFrame()
        timer = Timer.scheduledTimer(withTimeInterval: 0.22, repeats: true) { [weak self] _ in
            self?.captureNextFrame()
        }
    }

    @objc private func finishCapture() {
        stopTimer()
        processingQueue.async { [weak self] in
            guard let self else { return }
            let image = self.stitcher.makeImage()
            DispatchQueue.main.async { self.close(with: image) }
        }
    }

    @objc private func cancelCapture() {
        stopTimer()
        close(with: nil)
    }

    private func captureNextFrame() {
        guard !isProcessing, !stopped else { return }
        isProcessing = true
        let quartzRect = captureService.quartzRect(fromAppKitRect: rect)
        processingQueue.async { [weak self] in
            guard let self else { return }
            let image = self.captureService.capture(quartzRect: quartzRect)
            let result = image.map(self.stitcher.append)
            let now = Date()
            let shouldRefreshPreview: Bool
            switch result {
            case .started, .reachedMaximum, .incompatibleFrame:
                shouldRefreshPreview = true
            case .appended:
                shouldRefreshPreview = now.timeIntervalSince(self.lastPreviewAt) >= 0.5
            default:
                shouldRefreshPreview = false
            }
            let previewImage = shouldRefreshPreview ? self.stitcher.makeImage() : nil
            if shouldRefreshPreview { self.lastPreviewAt = now }
            DispatchQueue.main.async {
                self.isProcessing = false
                self.apply(result: result, previewImage: previewImage)
            }
        }
    }

    private func apply(result: ScrollAppendResult?, previewImage: CGImage?) {
        guard let result else {
            statusLabel?.stringValue = "Capture unavailable. Check Screen Recording permission."
            return
        }
        switch result {
        case .started(let height):
            statusLabel?.stringValue = "Ready — scroll down slowly · \(height) px"
        case .appended(_, let totalHeight):
            failures = 0
            statusLabel?.stringValue = "Stitching smoothly · \(totalHeight) px"
        case .noMatch(let totalHeight):
            failures += 1
            statusLabel?.stringValue = failures > 4
                ? "Paused — scroll more slowly · \(totalHeight) px saved"
                : "Waiting for vertical movement · \(totalHeight) px"
        case .reachedMaximum(let totalHeight):
            statusLabel?.stringValue = "Maximum height reached · \(totalHeight) px"
            finishCapture()
        case .incompatibleFrame(let totalHeight):
            statusLabel?.stringValue = "Display changed · \(totalHeight) px saved"
            finishCapture()
        }
        if let previewImage {
            preview?.image = NSImage(cgImage: previewImage, size: NSSize(width: previewImage.width, height: previewImage.height))
        }
    }

    private func showPanel() {
        let panelSize = NSSize(width: 252, height: 352)
        let visibleFrame = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1000, height: 800)
        var x = rect.maxX + 12
        if x + panelSize.width > visibleFrame.maxX { x = max(visibleFrame.minX, rect.minX - panelSize.width - 12) }
        let y = min(max(visibleFrame.minY, rect.maxY - panelSize.height), visibleFrame.maxY - panelSize.height)

        let panel = NSPanel(
            contentRect: CGRect(origin: CGPoint(x: x, y: y), size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false

        let root = MaterialCardView(frame: CGRect(origin: CGPoint(x: 6, y: 8), size: NSSize(width: 240, height: 338)))
        root.autoresizingMask = [.width, .height]

        let title = NSTextField(labelWithString: "Scrolling Capture")
        title.frame = CGRect(x: 16, y: 300, width: 172, height: 22)
        title.font = .systemFont(ofSize: 14, weight: .semibold)
        root.addSubview(title)

        let live = PillLabel(text: "LIVE", color: .systemGreen)
        live.frame = CGRect(x: 188, y: 302, width: 36, height: 18)
        live.font = .monospacedDigitSystemFont(ofSize: 9, weight: .bold)
        root.addSubview(live)

        let previewContainer = NSView(frame: CGRect(x: 14, y: 74, width: 212, height: 216))
        previewContainer.wantsLayer = true
        previewContainer.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.06).cgColor
        previewContainer.layer?.cornerRadius = 8
        previewContainer.layer?.masksToBounds = true
        root.addSubview(previewContainer)

        let preview = NSImageView(frame: previewContainer.bounds.insetBy(dx: 8, dy: 8))
        preview.imageScaling = .scaleProportionallyDown
        preview.autoresizingMask = [.width, .height]
        previewContainer.addSubview(preview)

        let status = NSTextField(labelWithString: "Starting capture…")
        status.frame = CGRect(x: 14, y: 48, width: 212, height: 18)
        status.alignment = .center
        status.font = .systemFont(ofSize: 11, weight: .medium)
        status.textColor = .secondaryLabelColor
        status.lineBreakMode = .byTruncatingMiddle
        root.addSubview(status)

        let finish = PrimaryButton(title: "Finish", target: self, action: #selector(finishCapture))
        finish.frame = CGRect(x: 116, y: 12, width: 108, height: 30)
        finish.keyEquivalent = "\r"
        root.addSubview(finish)

        let cancel = SymbolButton(symbol: "xmark", toolTip: "Cancel", target: self, action: #selector(cancelCapture))
        cancel.frame = CGRect(x: 14, y: 11, width: 32, height: 32)
        cancel.keyEquivalent = "\u{1b}"
        root.addSubview(cancel)

        let host = NSView(frame: CGRect(origin: .zero, size: panelSize))
        host.addSubview(root)
        panel.contentView = host
        panel.orderFrontRegardless()
        self.panel = panel
        self.statusLabel = status
        self.preview = preview
    }

    private func stopTimer() {
        stopped = true
        timer?.invalidate()
        timer = nil
    }

    private func close(with image: CGImage?) {
        panel?.orderOut(nil)
        panel = nil
        completion(image)
    }
}
