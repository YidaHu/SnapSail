import AppKit

final class SettingsWindowController: NSWindowController {
    private enum Page: Int, CaseIterable {
        case general, capture, scrolling, export, shortcuts

        var title: String {
            switch self {
            case .general: return "General"
            case .capture: return "Capture"
            case .scrolling: return "Scrolling"
            case .export: return "Export"
            case .shortcuts: return "Shortcuts"
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
    private var pageViews: [Page: NSView] = [:]
    private var tabButtons: [NSButton] = []

    private var formatPopup: NSPopUpButton!
    private var qualitySlider: NSSlider!
    private var qualityLabel: NSTextField!
    private var shadowButton: NSButton!
    private var soundButton: NSButton!
    private var notificationButton: NSButton!
    private var historyButton: NSButton!
    private var copyButton: NSButton!
    private var saveButton: NSButton!
    private var prefixField: NSTextField!
    private var pathLabel: NSTextField!

    init(preferences: AppPreferences) {
        self.preferences = preferences
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 720, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "SnapSail Preferences"
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
        addSectionTitle("App behavior", y: 430, to: general)
        soundButton = addCheckbox("Play a subtle sound after capture", y: 380, to: general)
        notificationButton = addCheckbox("Show a notification when capture completes", y: 342, to: general)
        historyButton = addCheckbox("Keep capture history on this Mac", y: 304, to: general)
        addHint("Your screenshots and history never leave this Mac.", y: 252, to: general)
        pageViews[.general] = general

        let capture = makePage()
        addSectionTitle("Screenshot behavior", y: 430, to: capture)
        shadowButton = addCheckbox("Include window shadow", y: 380, to: capture)
        copyButton = addCheckbox("Copy to clipboard after capture", y: 342, to: capture)
        saveButton = addCheckbox("Save to folder after capture", y: 304, to: capture)
        addHint("Hold Option while selecting to temporarily invert shadow behavior.", y: 252, to: capture)
        pageViews[.capture] = capture

        let scrolling = makePage()
        addSectionTitle("Scrolling capture", y: 430, to: scrolling)
        addFeatureRow(symbol: "arrow.down", title: "Scroll slowly and steadily", detail: "SnapSail matches overlapping rows while you scroll.", y: 350, to: scrolling)
        addFeatureRow(symbol: "hand.raised", title: "Stop on stable content", detail: "Avoid animated banners and fixed overlays for cleaner stitching.", y: 270, to: scrolling)
        addFeatureRow(symbol: "ruler", title: "Up to 60,000 pixels", detail: "The preview updates efficiently while the full image stays sharp.", y: 190, to: scrolling)
        pageViews[.scrolling] = scrolling

        let export = makePage()
        addSectionTitle("File output", y: 430, to: export)
        formatPopup = NSPopUpButton(frame: .zero)
        formatPopup.addItems(withTitles: ["PNG", "JPEG"])
        formatPopup.target = self
        formatPopup.action = #selector(saveValues)
        addRow(label: "Format:", control: formatPopup, y: 370, width: 140, to: export)

        let qualityStack = NSView(frame: .zero)
        qualitySlider = NSSlider(value: 0.9, minValue: 0.1, maxValue: 1, target: self, action: #selector(qualityChanged))
        qualitySlider.frame = CGRect(x: 0, y: 3, width: 230, height: 20)
        qualityStack.addSubview(qualitySlider)
        qualityLabel = NSTextField(labelWithString: "90%")
        qualityLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        qualityLabel.alignment = .right
        qualityLabel.frame = CGRect(x: 240, y: 4, width: 46, height: 18)
        qualityStack.addSubview(qualityLabel)
        addRow(label: "JPEG quality:", control: qualityStack, y: 320, width: 286, to: export)

        prefixField = NSTextField(frame: .zero)
        prefixField.target = self
        prefixField.action = #selector(saveValues)
        addRow(label: "Filename prefix:", control: prefixField, y: 270, width: 286, to: export)

        let folder = NSView(frame: .zero)
        pathLabel = NSTextField(labelWithString: "")
        pathLabel.lineBreakMode = .byTruncatingMiddle
        pathLabel.frame = CGRect(x: 0, y: 4, width: 206, height: 18)
        folder.addSubview(pathLabel)
        let choose = NSButton(title: "Choose…", target: self, action: #selector(chooseFolder))
        choose.bezelStyle = .rounded
        choose.frame = CGRect(x: 212, y: 0, width: 74, height: 26)
        folder.addSubview(choose)
        addRow(label: "Save folder:", control: folder, y: 220, width: 286, to: export)
        pageViews[.export] = export

        let shortcuts = makePage()
        addSectionTitle("Global shortcuts", y: 430, to: shortcuts)
        addShortcutRow(symbol: "viewfinder", title: "Capture Area", keys: "⌘ ⇧ 2", y: 365, to: shortcuts)
        addShortcutRow(symbol: "macwindow", title: "Capture Window", keys: "⌘ ⇧ 3", y: 305, to: shortcuts)
        addShortcutRow(symbol: "arrow.down.to.line.compact", title: "Scrolling Capture", keys: "⌘ ⇧ 4", y: 245, to: shortcuts)
        addHint("Shortcuts work while SnapSail is running in the menu bar.", y: 174, to: shortcuts)
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
        for (candidate, view) in pageViews { view.isHidden = candidate != page }
        for button in tabButtons {
            let selected = button.tag == page.rawValue
            button.contentTintColor = selected ? SnapSailStyle.accent : .secondaryLabelColor
            button.font = .systemFont(ofSize: 11, weight: selected ? .semibold : .medium)
        }
    }

    private func loadValues() {
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
    }

    @objc private func qualityChanged() {
        qualityLabel.stringValue = "\(Int(qualitySlider.doubleValue * 100))%"
        saveValues()
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

    private func addShortcutRow(symbol: String, title: String, keys: String, y: CGFloat, to view: NSView) {
        let card = NSView(frame: CGRect(x: 176, y: y, width: 368, height: 46))
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
        let keyLabel = NSTextField(labelWithString: keys)
        keyLabel.font = .monospacedSystemFont(ofSize: 12, weight: .semibold)
        keyLabel.alignment = .center
        keyLabel.frame = CGRect(x: 262, y: 11, width: 92, height: 22)
        keyLabel.drawsBackground = true
        keyLabel.backgroundColor = NSColor.labelColor.withAlphaComponent(0.07)
        keyLabel.wantsLayer = true
        keyLabel.layer?.cornerRadius = 5
        card.addSubview(keyLabel)
    }
}
