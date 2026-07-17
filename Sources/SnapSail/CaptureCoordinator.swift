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
    private lazy var settingsController = SettingsWindowController(
        preferences: preferences,
        onShortcutChange: { [weak self] action, shortcut in
            self?.replaceShortcut(shortcut, for: action) ?? false
        },
        onLanguageChange: { [weak self] in
            guard let self else { return }
            self.menuBar?.updateLanguage(shortcuts: self.preferences.shortcuts)
        }
    )
    private let historyStore = HistoryStore()
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

        if !installHotKeys() {
            CaptureShortcutAction.allCases.forEach { preferences.resetShortcut(for: $0) }
            _ = installHotKeys()
        }
    }

    func stop() {
        selectionOverlay?.cancel()
        selectionOverlay = nil
        hotKeys?.unregisterAll()
        hotKeys = nil
    }

    private func installHotKeys() -> Bool {
        hotKeys?.unregisterAll()
        hotKeys = nil

        let manager = GlobalHotKeyManager()
        for action in CaptureShortcutAction.allCases {
            let shortcut = preferences.shortcut(for: action)
            let registered = manager.register(
                id: action.registrationID,
                keyCode: shortcut.keyCode,
                modifiers: carbonModifiers(shortcut.modifiers),
                action: shortcutAction(for: action)
            )
            guard registered else {
                manager.unregisterAll()
                return false
            }
        }
        hotKeys = manager
        menuBar?.updateShortcuts(preferences.shortcuts)
        return true
    }

    private func replaceShortcut(_ shortcut: KeyboardShortcut, for action: CaptureShortcutAction) -> Bool {
        guard !shortcut.conflicts(for: action, among: preferences.shortcuts) else { return false }
        let previous = preferences.shortcut(for: action)
        preferences.setShortcut(shortcut, for: action)
        if installHotKeys() { return true }

        preferences.setShortcut(previous, for: action)
        _ = installHotKeys()
        return false
    }

    private func shortcutAction(for action: CaptureShortcutAction) -> () -> Void {
        switch action {
        case .area:
            return { [weak self] in self?.beginAreaCapture(scrolling: false) }
        case .window:
            return { [weak self] in self?.beginWindowCapture() }
        case .scrolling:
            return { [weak self] in self?.beginAreaCapture(scrolling: true) }
        }
    }

    private func carbonModifiers(_ modifiers: ShortcutModifiers) -> UInt32 {
        var result: UInt32 = 0
        if modifiers.contains(.command) { result |= UInt32(cmdKey) }
        if modifiers.contains(.shift) { result |= UInt32(shiftKey) }
        if modifiers.contains(.option) { result |= UInt32(optionKey) }
        if modifiers.contains(.control) { result |= UInt32(controlKey) }
        return result
    }

    private func beginAreaCapture(scrolling: Bool) {
        guard selectionOverlay == nil else { return }
        guard ensurePermission() else { return }
        guard let frozenDesktop = captureService.freezeDesktop() else {
            showCaptureFailure()
            return
        }
        selectionOverlay = SelectionOverlayController(
            mode: .region,
            captureService: captureService,
            frozenDesktop: frozenDesktop
        ) { [weak self] outcome in
            guard let self else { return }
            self.selectionOverlay = nil
            guard let outcome, case .region(let rect) = outcome.selection else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                let action: SelectionAction = scrolling ? .scroll : outcome.action
                if action == .scroll { self.startScrolling(rect: rect) }
                else if let image = frozenDesktop.image(in: rect),
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
        guard selectionOverlay == nil else { return }
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
        case .capture:
            recordAndCopy(image)
            if preferences.saveAfterCapture {
                _ = try? ImageExporter.save(image, to: preferences.saveDirectory, preferences: preferences)
            }
        case .copy, .scroll:
            recordAndCopy(image)
        case .save:
            record(image)
            _ = try? ImageExporter.save(image, to: preferences.saveDirectory, preferences: preferences)
        case .pin:
            recordAndCopy(image)
            PinWindowRegistry.shared.pin(image)
        }
    }

    private func recordAndCopy(_ image: CGImage) {
        record(image)
        ImageExporter.copyToPasteboard(image)
    }

    private func record(_ image: CGImage) {
        if preferences.historyEnabled { historyStore.add(image: image) }
        if preferences.playSound { NSSound(named: "Tink")?.play() }
    }

    private func ensurePermission() -> Bool {
        if captureService.hasPermission() { return true }
        let requested = captureService.requestPermission()
        if requested { return true }

        let alert = NSAlert()
        alert.messageText = L10n.text(.permissionTitle)
        alert.informativeText = L10n.text(.permissionBody)
        alert.addButton(withTitle: L10n.text(.openSystemSettings))
        alert.addButton(withTitle: L10n.text(.cancel))
        NSApplication.shared.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
        return false
    }

    private func showCaptureFailure() {
        let alert = NSAlert()
        alert.messageText = L10n.text(.captureFailed)
        alert.informativeText = L10n.text(.captureFailedBody)
        alert.runModal()
    }
}
