import AppKit
import Carbon.HIToolbox
import SnapSailCore

final class CaptureCoordinator {
    private let preferences = AppPreferences.shared
    private let captureService = CaptureService()
    private var menuBar: MenuBarController?
    private var hotKeys: GlobalHotKeyManager?
    private var selectionOverlay: SelectionOverlayController?
    private var scrollController: ScrollCaptureController?
    private var editorControllers: [EditorWindowController] = []
    private lazy var settingsController = SettingsWindowController(preferences: preferences)
    private lazy var historyStore = HistoryStore()
    private lazy var historyController = HistoryWindowController(store: historyStore) { [weak self] image in
        self?.presentEditor(image)
    }

    func start() {
        let menuBar = MenuBarController()
        menuBar.onCaptureArea = { [weak self] in self?.beginAreaCapture(scrolling: false) }
        menuBar.onCaptureWindow = { [weak self] in self?.beginWindowCapture() }
        menuBar.onScrollingCapture = { [weak self] in self?.beginAreaCapture(scrolling: true) }
        menuBar.onSettings = { [weak self] in self?.settingsController.showWindow(nil) }
        menuBar.onHistory = { [weak self] in self?.historyController.showWindow(nil) }
        self.menuBar = menuBar

        let hotKeys = GlobalHotKeyManager()
        let modifiers = UInt32(cmdKey | shiftKey)
        _ = hotKeys.register(id: 2, keyCode: UInt32(kVK_ANSI_2), modifiers: modifiers) { [weak self] in
            self?.beginAreaCapture(scrolling: false)
        }
        _ = hotKeys.register(id: 3, keyCode: UInt32(kVK_ANSI_3), modifiers: modifiers) { [weak self] in
            self?.beginWindowCapture()
        }
        _ = hotKeys.register(id: 4, keyCode: UInt32(kVK_ANSI_4), modifiers: modifiers) { [weak self] in
            self?.beginAreaCapture(scrolling: true)
        }
        self.hotKeys = hotKeys
    }

    func stop() {
        selectionOverlay?.cancel()
        selectionOverlay = nil
        hotKeys?.unregisterAll()
        hotKeys = nil
    }

    private func beginAreaCapture(scrolling: Bool) {
        guard ensurePermission() else { return }
        selectionOverlay = SelectionOverlayController(mode: .region, captureService: captureService) { [weak self] outcome in
            guard let self else { return }
            self.selectionOverlay = nil
            guard let outcome, case .region(let rect) = outcome.selection else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                let action: SelectionAction = scrolling ? .scroll : outcome.action
                if action == .scroll { self.startScrolling(rect: rect) }
                else if let image = self.captureService.capture(appKitRect: rect),
                        let rendered = InlineAnnotationRenderer.render(
                            base: image,
                            annotations: outcome.annotations,
                            selectionPointSize: outcome.selectionPointSize
                        ) {
                    let shadowed = ScreenshotShadowRenderer.render(rendered) ?? rendered
                    self.finishCapture(shadowed, action: action)
                }
                else { self.showCaptureFailure() }
            }
        }
        selectionOverlay?.begin()
    }

    private func beginWindowCapture() {
        guard ensurePermission() else { return }
        selectionOverlay = SelectionOverlayController(mode: .window, captureService: captureService) { [weak self] outcome in
            guard let self else { return }
            self.selectionOverlay = nil
            guard let outcome, case .windows(let windows) = outcome.selection else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                let images = windows.compactMap {
                    self.captureService.capture(window: $0, includeShadow: self.preferences.includeWindowShadow)
                }
                guard let image = ImageUtilities.stack(images: images) else { return self.showCaptureFailure() }
                self.finishCapture(image, action: outcome.action == .scroll ? .capture : outcome.action)
            }
        }
        selectionOverlay?.begin()
    }

    private func startScrolling(rect: CGRect) {
        let controller = ScrollCaptureController(rect: rect, captureService: captureService) { [weak self] image in
            self?.scrollController = nil
            if let image {
                self?.finishCapture(ScreenshotShadowRenderer.render(image) ?? image, action: .copy)
            }
        }
        scrollController = controller
        controller.start()
    }

    private func presentEditor(_ image: CGImage) {
        if preferences.historyEnabled { historyStore.add(image: image) }
        if preferences.playSound { NSSound(named: "Tink")?.play() }

        if preferences.copyAfterCapture { ImageExporter.copyToPasteboard(image) }
        if preferences.saveAfterCapture {
            _ = try? ImageExporter.save(image, to: preferences.saveDirectory, preferences: preferences)
        }

        let controller = EditorWindowController(image: image, preferences: preferences) { [weak self] controller in
            self?.editorControllers.removeAll { $0 === controller }
        }
        editorControllers.append(controller)
        controller.showWindow(nil)
    }

    private func finishCapture(_ image: CGImage, action: SelectionAction) {
        switch action {
        case .capture, .copy, .scroll:
            recordAndCopy(image)
            if preferences.saveAfterCapture {
                _ = try? ImageExporter.save(image, to: preferences.saveDirectory, preferences: preferences)
            }
        case .save:
            recordAndCopy(image)
            ImageExporter.presentSavePanel(for: image, preferences: preferences, window: nil)
        case .pin:
            recordAndCopy(image)
            PinWindowRegistry.shared.pin(image)
        }
    }

    private func recordAndCopy(_ image: CGImage) {
        if preferences.historyEnabled { historyStore.add(image: image) }
        ImageExporter.copyToPasteboard(image)
        if preferences.playSound { NSSound(named: "Tink")?.play() }
    }

    private func ensurePermission() -> Bool {
        if captureService.hasPermission() { return true }
        let requested = captureService.requestPermission()
        if requested { return true }

        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "SnapSail needs Screen Recording access to capture your screen. Enable it in System Settings → Privacy & Security → Screen Recording, then relaunch SnapSail."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        NSApplication.shared.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
        return false
    }

    private func showCaptureFailure() {
        let alert = NSAlert()
        alert.messageText = "Capture Failed"
        alert.informativeText = "SnapSail could not capture this content. Check Screen Recording permission and try again."
        alert.runModal()
    }
}
