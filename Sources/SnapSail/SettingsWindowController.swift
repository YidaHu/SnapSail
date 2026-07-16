import AppKit
import SnapSailCore

final class SettingsWindowController: NSWindowController {
    private enum Page: Int, CaseIterable {
        case general, capture, scrolling, export, shortcuts

        var title: String {
            switch self {
            case .general: return L10n.text(.general)
            case .capture: return L10n.text(.capture)
            case .scrolling: return L10n.text(.scrolling)
            case .export: return L10n.text(.export)
            case .shortcuts: return L10n.text(.shortcuts)
            }
        }

        var symbol: String {
            switch self {
            case .general: return "switch.2"
            case .capture: return "viewfinder"
            case .scrolling: return "arrow.down.to.line.compact"
            case .export: return "square.and.arrow.up"
            case .shortcuts: return "command"
            }
        }
    }

    private let preferences: AppPreferences
    private let launchAtLogin: LaunchAtLoginManaging
    private let onShortcutChange: (CaptureShortcutAction, KeyboardShortcut) -> Bool
    private let onLanguageChange: () -> Void
    private var pageViews: [Page: NSView] = [:]
    private var tabButtons: [NSButton] = []
    private var currentPage: Page = .general

    private var formatPopup: NSPopUpButton!
    private var qualitySlider: NSSlider!
    private var qualityLabel: NSTextField!
    private var shadowButton: NSButton!
    private var soundButton: NSButton!
    private var launchAtLoginButton: NSButton!
    private var notificationButton: NSButton!
    private var historyButton: NSButton!
    private var copyButton: NSButton!
    private var saveButton: NSButton!
    private var prefixField: NSTextField!
    private var pathLabel: NSTextField!
    private var languagePopup: NSPopUpButton!
    private var shortcutRecorders: [CaptureShortcutAction: ShortcutRecorderButton] = [:]

    init(
        preferences: AppPreferences,
        launchAtLogin: LaunchAtLoginManaging = LaunchAtLoginController(),
        onShortcutChange: @escaping (CaptureShortcutAction, KeyboardShortcut) -> Bool = { _, _ in false },
        onLanguageChange: @escaping () -> Void = {}
    ) {
        self.preferences = preferences
        self.launchAtLogin = launchAtLogin
        self.onShortcutChange = onShortcutChange
        self.onLanguageChange = onLanguageChange
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 720, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.text(.preferencesTitle)
        window.center()
        window.isReleasedWhenClosed = false
        super.init(window: window)
        buildInterface()
        show(page: .general)
        loadValues()
    }

    required init?(coder: NSCoder) { nil }

    override func showWindow(_ sender: Any?) {
        loadValues()
        super.showWindow(sender)
        NSApplication.shared.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    private func buildInterface() {
        guard let content = window?.contentView else { return }
        content.subviews.forEach { $0.removeFromSuperview() }
        pageViews.removeAll()
        tabButtons.removeAll()
        shortcutRecorders.removeAll()
        window?.title = L10n.text(.preferencesTitle)

        let toolbar = NSVisualEffectView(frame: CGRect(x: 0, y: 500, width: 720, height: 100))
        toolbar.material = .headerView
        toolbar.blendingMode = .withinWindow
        content.addSubview(toolbar)

        let totalWidth: CGFloat = 5 * 84
        var x = (720 - totalWidth) / 2
        for page in Page.allCases {
            let button = NSButton(title: page.title, target: self, action: #selector(selectPage(_:)))
            button.tag = page.rawValue
            button.image = SnapSailStyle.symbol(page.symbol, size: 25, weight: .regular)
            button.imagePosition = .imageAbove
            button.isBordered = false
            button.font = .systemFont(ofSize: 11, weight: .medium)
            button.contentTintColor = .secondaryLabelColor
            button.frame = CGRect(x: x, y: 12, width: 84, height: 76)
            toolbar.addSubview(button)
            tabButtons.append(button)
            x += 84
        }

        let separator = NSBox(frame: CGRect(x: 0, y: 499, width: 720, height: 1))
        separator.boxType = .separator
        content.addSubview(separator)

        let general = makePage()
        addSectionTitle(L10n.text(.appBehavior), y: 430, to: general)
        launchAtLoginButton = addCheckbox(L10n.text(.launchAtLogin), y: 378, to: general)
        launchAtLoginButton.identifier = NSUserInterfaceItemIdentifier("settings.launchAtLogin")
        launchAtLoginButton.target = self
        launchAtLoginButton.action = #selector(launchAtLoginChanged)
        soundButton = addCheckbox(L10n.text(.playSound), y: 340, to: general)
        notificationButton = addCheckbox(L10n.text(.showNotification), y: 302, to: general)
        historyButton = addCheckbox(L10n.text(.keepHistory), y: 264, to: general)
        languagePopup = NSPopUpButton(frame: .zero)
        languagePopup.addItems(withTitles: AppLanguage.allCases.map(\.displayName))
        languagePopup.target = self
        languagePopup.action = #selector(languageChanged)
        addRow(label: L10n.text(.language), control: languagePopup, y: 210, width: 180, to: general)
        addHint(L10n.text(.privacyHint), y: 154, to: general)
        pageViews[.general] = general

        let capture = makePage()
        addSectionTitle(L10n.text(.screenshotBehavior), y: 430, to: capture)
        shadowButton = addCheckbox(L10n.text(.includeWindowShadow), y: 380, to: capture)
        copyButton = addCheckbox(L10n.text(.copyAfterCapture), y: 342, to: capture)
        saveButton = addCheckbox(L10n.text(.saveAfterCapture), y: 304, to: capture)
        addHint(L10n.text(.shadowHint), y: 252, to: capture)
        pageViews[.capture] = capture

        let scrolling = makePage()
        addSectionTitle(L10n.text(.scrollingCapture), y: 430, to: scrolling)
        addFeatureRow(symbol: "arrow.down", title: L10n.text(.scrollSlow), detail: L10n.text(.scrollSlowDetail), y: 350, to: scrolling)
        addFeatureRow(symbol: "hand.raised", title: L10n.text(.stopStable), detail: L10n.text(.stopStableDetail), y: 270, to: scrolling)
        addFeatureRow(symbol: "ruler", title: L10n.text(.maxPixels), detail: L10n.text(.maxPixelsDetail), y: 190, to: scrolling)
        pageViews[.scrolling] = scrolling

        let export = makePage()
        addSectionTitle(L10n.text(.fileOutput), y: 430, to: export)
        formatPopup = NSPopUpButton(frame: .zero)
        formatPopup.addItems(withTitles: ["PNG", "JPEG"])
        formatPopup.target = self
        formatPopup.action = #selector(saveValues)
        addRow(label: L10n.text(.format), control: formatPopup, y: 370, width: 140, to: export)

        let qualityStack = NSView(frame: .zero)
        qualitySlider = NSSlider(value: 0.9, minValue: 0.1, maxValue: 1, target: self, action: #selector(qualityChanged))
        qualitySlider.frame = CGRect(x: 0, y: 3, width: 230, height: 20)
        qualityStack.addSubview(qualitySlider)
        qualityLabel = NSTextField(labelWithString: "90%")
        qualityLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        qualityLabel.alignment = .right
        qualityLabel.frame = CGRect(x: 240, y: 4, width: 46, height: 18)
        qualityStack.addSubview(qualityLabel)
        addRow(label: L10n.text(.jpegQuality), control: qualityStack, y: 320, width: 286, to: export)

        prefixField = NSTextField(frame: .zero)
        prefixField.target = self
        prefixField.action = #selector(saveValues)
        addRow(label: L10n.text(.filenamePrefix), control: prefixField, y: 270, width: 286, to: export)

        let folder = NSView(frame: .zero)
        pathLabel = NSTextField(labelWithString: "")
        pathLabel.lineBreakMode = .byTruncatingMiddle
        pathLabel.frame = CGRect(x: 0, y: 4, width: 206, height: 18)
        folder.addSubview(pathLabel)
        let choose = NSButton(title: L10n.text(.choose), target: self, action: #selector(chooseFolder))
        choose.bezelStyle = .rounded
        choose.frame = CGRect(x: 212, y: 0, width: 74, height: 26)
        folder.addSubview(choose)
        addRow(label: L10n.text(.saveFolder), control: folder, y: 220, width: 286, to: export)
        pageViews[.export] = export

        let shortcuts = makePage()
        addSectionTitle(L10n.text(.globalShortcuts), y: 430, to: shortcuts)
        addShortcutRow(symbol: "viewfinder", title: L10n.text(.captureArea), action: .area, y: 365, to: shortcuts)
        addShortcutRow(symbol: "macwindow", title: L10n.text(.captureWindow), action: .window, y: 305, to: shortcuts)
        addShortcutRow(symbol: "arrow.down.to.line.compact", title: L10n.text(.scrollingCapture), action: .scrolling, y: 245, to: shortcuts)
        addHint(L10n.text(.shortcutHint), y: 174, to: shortcuts)
        pageViews[.shortcuts] = shortcuts

        for page in Page.allCases {
            if let view = pageViews[page] { content.addSubview(view) }
        }

        [shadowButton, soundButton, notificationButton, historyButton, copyButton, saveButton].forEach {
            $0?.target = self
            $0?.action = #selector(saveValues)
        }
    }

    private func makePage() -> NSView {
        let view = NSView(frame: CGRect(x: 0, y: 0, width: 720, height: 499))
        view.isHidden = true
        return view
    }

    @objc private func selectPage(_ sender: NSButton) {
        guard let page = Page(rawValue: sender.tag) else { return }
        show(page: page)
    }

    private func show(page: Page) {
        currentPage = page
        for (candidate, view) in pageViews { view.isHidden = candidate != page }
        for button in tabButtons {
            let selected = button.tag == page.rawValue
            button.contentTintColor = selected ? SnapSailStyle.accent : .secondaryLabelColor
            button.font = .systemFont(ofSize: 11, weight: selected ? .semibold : .medium)
        }
    }

    private func loadValues() {
        loadLaunchAtLoginState()
        shadowButton?.state = preferences.includeWindowShadow ? .on : .off
        soundButton?.state = preferences.playSound ? .on : .off
        notificationButton?.state = preferences.showNotification ? .on : .off
        historyButton?.state = preferences.historyEnabled ? .on : .off
        copyButton?.state = preferences.copyAfterCapture ? .on : .off
        saveButton?.state = preferences.saveAfterCapture ? .on : .off
        formatPopup?.selectItem(at: preferences.outputFormat == .png ? 0 : 1)
        qualitySlider?.doubleValue = preferences.jpegQuality
        qualityLabel?.stringValue = "\(Int(preferences.jpegQuality * 100))%"
        prefixField?.stringValue = preferences.filenamePrefix
        pathLabel?.stringValue = preferences.saveDirectory.path
        languagePopup?.selectItem(at: preferences.language == .english ? 0 : 1)
        for action in CaptureShortcutAction.allCases {
            shortcutRecorders[action]?.setShortcut(preferences.shortcut(for: action))
        }
    }

    @objc private func qualityChanged() {
        qualityLabel.stringValue = "\(Int(qualitySlider.doubleValue * 100))%"
        saveValues()
    }

    @objc private func launchAtLoginChanged() {
        do {
            try launchAtLogin.setEnabled(launchAtLoginButton.state == .on)
        } catch {
            showLaunchAtLoginAlert(error: error)
        }
        loadLaunchAtLoginState()
    }

    private func loadLaunchAtLoginState() {
        guard let launchAtLoginButton else { return }
        switch launchAtLogin.status {
        case .disabled:
            launchAtLoginButton.state = .off
            launchAtLoginButton.isEnabled = true
            launchAtLoginButton.toolTip = nil
        case .enabled:
            launchAtLoginButton.state = .on
            launchAtLoginButton.isEnabled = true
            launchAtLoginButton.toolTip = nil
        case .requiresApproval:
            launchAtLoginButton.state = .on
            launchAtLoginButton.isEnabled = true
            launchAtLoginButton.toolTip = L10n.text(.launchAtLoginApproval)
        case .unavailable:
            launchAtLoginButton.state = .off
            launchAtLoginButton.isEnabled = false
            launchAtLoginButton.toolTip = L10n.text(.launchAtLoginUnavailable)
        }
    }

    private func showLaunchAtLoginAlert(error: Error) {
        let alert = NSAlert()
        alert.messageText = L10n.text(.launchAtLoginFailed)
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: L10n.text(.ok))
        if let window { alert.beginSheetModal(for: window) }
        else { alert.runModal() }
    }

    @objc private func languageChanged() {
        preferences.language = languagePopup.indexOfSelectedItem == 0 ? .english : .simplifiedChinese
        onLanguageChange()
        applyLanguage()
    }

    func applyLanguage() {
        let page = currentPage
        buildInterface()
        show(page: page)
        loadValues()
    }

    @objc private func saveValues() {
        preferences.includeWindowShadow = shadowButton.state == .on
        preferences.playSound = soundButton.state == .on
        preferences.showNotification = notificationButton.state == .on
        preferences.historyEnabled = historyButton.state == .on
        preferences.copyAfterCapture = copyButton.state == .on
        preferences.saveAfterCapture = saveButton.state == .on
        preferences.outputFormat = formatPopup.indexOfSelectedItem == 0 ? .png : .jpeg
        preferences.jpegQuality = qualitySlider.doubleValue
        preferences.filenamePrefix = prefixField.stringValue
    }

    @objc private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = preferences.saveDirectory
        guard panel.runModal() == .OK, let url = panel.url else { return }
        preferences.saveDirectory = url
        pathLabel.stringValue = url.path
    }

    private func addSectionTitle(_ title: String, y: CGFloat, to view: NSView) {
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.alignment = .center
        label.frame = CGRect(x: 160, y: y, width: 400, height: 26)
        view.addSubview(label)
    }

    private func addCheckbox(_ title: String, y: CGFloat, to view: NSView) -> NSButton {
        let button = NSButton(checkboxWithTitle: title, target: nil, action: nil)
        button.font = .systemFont(ofSize: 13)
        button.frame = CGRect(x: 226, y: y, width: 380, height: 24)
        view.addSubview(button)
        return button
    }

    private func addHint(_ text: String, y: CGFloat, to view: NSView) {
        let hint = NSTextField(wrappingLabelWithString: text)
        hint.textColor = .secondaryLabelColor
        hint.alignment = .center
        hint.font = .systemFont(ofSize: 12)
        hint.frame = CGRect(x: 150, y: y, width: 420, height: 38)
        view.addSubview(hint)
    }

    private func addRow(label text: String, control: NSView, y: CGFloat, width: CGFloat, to view: NSView) {
        let label = NSTextField(labelWithString: text)
        label.alignment = .right
        label.frame = CGRect(x: 96, y: y + 4, width: 150, height: 20)
        view.addSubview(label)
        control.frame = CGRect(x: 260, y: y, width: width, height: 28)
        view.addSubview(control)
    }

    private func addFeatureRow(symbol: String, title: String, detail: String, y: CGFloat, to view: NSView) {
        let icon = NSImageView(frame: CGRect(x: 166, y: y + 4, width: 30, height: 30))
        icon.image = SnapSailStyle.symbol(symbol, size: 23, weight: .regular)
        icon.contentTintColor = SnapSailStyle.accent
        view.addSubview(icon)
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.frame = CGRect(x: 216, y: y + 20, width: 350, height: 18)
        view.addSubview(titleLabel)
        let detailLabel = NSTextField(labelWithString: detail)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.font = .systemFont(ofSize: 12)
        detailLabel.frame = CGRect(x: 216, y: y - 2, width: 380, height: 18)
        view.addSubview(detailLabel)
    }

    private func addShortcutRow(
        symbol: String,
        title: String,
        action: CaptureShortcutAction,
        y: CGFloat,
        to view: NSView
    ) {
        let card = NSView(frame: CGRect(x: 150, y: y, width: 420, height: 46))
        card.wantsLayer = true
        card.layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.045).cgColor
        card.layer?.cornerRadius = 8
        view.addSubview(card)
        let icon = NSImageView(frame: CGRect(x: 13, y: 10, width: 24, height: 24))
        icon.image = SnapSailStyle.symbol(symbol, size: 17)
        icon.contentTintColor = SnapSailStyle.accent
        card.addSubview(icon)
        let label = NSTextField(labelWithString: title)
        label.frame = CGRect(x: 50, y: 13, width: 190, height: 20)
        card.addSubview(label)
        let recorder = ShortcutRecorderButton(action: action, shortcut: preferences.shortcut(for: action))
        recorder.frame = CGRect(x: 250, y: 8, width: 156, height: 30)
        recorder.onShortcutProposed = { [weak self] candidate in
            self?.applyShortcut(candidate, for: action) ?? false
        }
        card.addSubview(recorder)
        shortcutRecorders[action] = recorder
    }

    private func applyShortcut(_ shortcut: KeyboardShortcut, for action: CaptureShortcutAction) -> Bool {
        if shortcut.conflicts(for: action, among: preferences.shortcuts) {
            showShortcutAlert(message: L10n.text(.shortcutDuplicate))
            return false
        }
        guard onShortcutChange(action, shortcut) else {
            showShortcutAlert(message: L10n.text(.shortcutSystemConflict))
            return false
        }
        loadValues()
        return true
    }

    private func showShortcutAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = L10n.text(.shortcutUnavailable)
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: L10n.text(.ok))
        if let window { alert.beginSheetModal(for: window) }
        else { alert.runModal() }
    }
}
