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
            let previewImage = self.stitcher.makeImage()
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
        let panelSize = NSSize(width: 300, height: 330)
        let visibleFrame = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1000, height: 800)
        var x = rect.maxX + 12
        if x + panelSize.width > visibleFrame.maxX { x = max(visibleFrame.minX, rect.minX - panelSize.width - 12) }
        let y = min(max(visibleFrame.minY, rect.maxY - panelSize.height), visibleFrame.maxY - panelSize.height)

        let panel = NSPanel(
            contentRect: CGRect(origin: CGPoint(x: x, y: y), size: panelSize),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "Scrolling Capture"
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let root = NSView(frame: CGRect(origin: .zero, size: panelSize))
        let preview = NSImageView(frame: CGRect(x: 18, y: 72, width: 264, height: 218))
        preview.imageScaling = .scaleProportionallyDown
        preview.wantsLayer = true
        preview.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        preview.layer?.cornerRadius = 8
        root.addSubview(preview)

        let status = NSTextField(labelWithString: "Starting capture…")
        status.frame = CGRect(x: 18, y: 45, width: 264, height: 20)
        status.alignment = .center
        status.font = .systemFont(ofSize: 12)
        root.addSubview(status)

        let finish = NSButton(title: "Finish", target: self, action: #selector(finishCapture))
        finish.frame = CGRect(x: 66, y: 10, width: 90, height: 30)
        finish.keyEquivalent = "\r"
        root.addSubview(finish)

        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancelCapture))
        cancel.frame = CGRect(x: 158, y: 10, width: 80, height: 30)
        cancel.keyEquivalent = "\u{1b}"
        root.addSubview(cancel)

        panel.contentView = root
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
