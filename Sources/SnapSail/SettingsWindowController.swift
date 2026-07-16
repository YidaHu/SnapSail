import AppKit

final class SettingsWindowController: NSWindowController {
    private let preferences: AppPreferences
    private var formatPopup: NSPopUpButton!
    private var qualitySlider: NSSlider!
    private var shadowButton: NSButton!
    private var soundButton: NSButton!
    private var historyButton: NSButton!
    private var copyButton: NSButton!
    private var saveButton: NSButton!
    private var prefixField: NSTextField!
    private var pathLabel: NSTextField!

    init(preferences: AppPreferences) {
        self.preferences = preferences
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 620, height: 510),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "SnapSail Settings"
        window.center()
        super.init(window: window)
        buildInterface()
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
        var y: CGFloat = 462
        addHeader("Capture", y: &y, to: content)
        shadowButton = checkbox("Include window shadow", y: &y, to: content)
        soundButton = checkbox("Play sound after capture", y: &y, to: content)
        historyButton = checkbox("Keep local capture history", y: &y, to: content)

        y -= 10
        addHeader("After Capture", y: &y, to: content)
        copyButton = checkbox("Copy to clipboard automatically", y: &y, to: content)
        saveButton = checkbox("Save to folder automatically", y: &y, to: content)

        y -= 10
        addHeader("Export", y: &y, to: content)
        addLabel("Format", x: 34, y: y, to: content)
        formatPopup = NSPopUpButton(frame: CGRect(x: 180, y: y - 4, width: 120, height: 28))
        formatPopup.addItems(withTitles: ["PNG", "JPEG"])
        formatPopup.target = self
        formatPopup.action = #selector(saveValues)
        content.addSubview(formatPopup)
        y -= 34

        addLabel("JPEG quality", x: 34, y: y, to: content)
        qualitySlider = NSSlider(value: 0.9, minValue: 0.1, maxValue: 1, target: self, action: #selector(saveValues))
        qualitySlider.frame = CGRect(x: 180, y: y, width: 220, height: 20)
        content.addSubview(qualitySlider)
        y -= 36

        addLabel("Filename prefix", x: 34, y: y, to: content)
        prefixField = NSTextField(frame: CGRect(x: 180, y: y - 3, width: 220, height: 24))
        prefixField.target = self
        prefixField.action = #selector(saveValues)
        content.addSubview(prefixField)
        y -= 38

        addLabel("Save folder", x: 34, y: y, to: content)
        pathLabel = NSTextField(labelWithString: "")
        pathLabel.frame = CGRect(x: 180, y: y, width: 320, height: 20)
        pathLabel.lineBreakMode = .byTruncatingMiddle
        content.addSubview(pathLabel)
        let choose = NSButton(title: "Choose…", target: self, action: #selector(chooseFolder))
        choose.frame = CGRect(x: 500, y: y - 5, width: 90, height: 28)
        content.addSubview(choose)

        let footer = NSTextField(wrappingLabelWithString: "Shortcuts: ⌘⇧2 Area · ⌘⇧3 Window · ⌘⇧4 Scrolling Capture\nAll screenshots and history stay on this Mac.")
        footer.frame = CGRect(x: 34, y: 18, width: 540, height: 44)
        footer.textColor = .secondaryLabelColor
        content.addSubview(footer)

        [shadowButton, soundButton, historyButton, copyButton, saveButton].forEach {
            $0?.target = self
            $0?.action = #selector(saveValues)
        }
    }

    private func loadValues() {
        shadowButton?.state = preferences.includeWindowShadow ? .on : .off
        soundButton?.state = preferences.playSound ? .on : .off
        historyButton?.state = preferences.historyEnabled ? .on : .off
        copyButton?.state = preferences.copyAfterCapture ? .on : .off
        saveButton?.state = preferences.saveAfterCapture ? .on : .off
        formatPopup?.selectItem(at: preferences.outputFormat == .png ? 0 : 1)
        qualitySlider?.doubleValue = preferences.jpegQuality
        prefixField?.stringValue = preferences.filenamePrefix
        pathLabel?.stringValue = preferences.saveDirectory.path
    }

    @objc private func saveValues() {
        preferences.includeWindowShadow = shadowButton.state == .on
        preferences.playSound = soundButton.state == .on
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

    private func addHeader(_ title: String, y: inout CGFloat, to view: NSView) {
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.frame = CGRect(x: 24, y: y, width: 300, height: 22)
        view.addSubview(label)
        y -= 34
    }

    private func checkbox(_ title: String, y: inout CGFloat, to view: NSView) -> NSButton {
        let button = NSButton(checkboxWithTitle: title, target: nil, action: nil)
        button.frame = CGRect(x: 34, y: y, width: 430, height: 22)
        view.addSubview(button)
        y -= 28
        return button
    }

    private func addLabel(_ title: String, x: CGFloat, y: CGFloat, to view: NSView) {
        let label = NSTextField(labelWithString: title)
        label.frame = CGRect(x: x, y: y, width: 140, height: 20)
        view.addSubview(label)
    }
}
