import AppKit
import Foundation

final class HistoryStore {
    private let directory: URL

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        directory = support.appendingPathComponent("SnapSail/History", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func add(image: CGImage) {
        let name = "capture-\(Int(Date().timeIntervalSince1970 * 1000)).png"
        let url = directory.appendingPathComponent(name)
        guard let data = ImageExporter.data(for: image, format: .png, quality: 1) else { return }
        try? data.write(to: url, options: .atomic)
        trim(to: 200)
    }

    func items() -> [URL] {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        return urls.filter { $0.pathExtension.lowercased() == "png" }.sorted {
            let left = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let right = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return left > right
        }
    }

    func image(at url: URL) -> CGImage? {
        guard let nsImage = NSImage(contentsOf: url) else { return nil }
        var rect = CGRect(origin: .zero, size: nsImage.size)
        return nsImage.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }

    func clear() {
        items().forEach { try? FileManager.default.removeItem(at: $0) }
    }

    private func trim(to limit: Int) {
        let oldItems = Array(items().dropFirst(limit))
        oldItems.forEach { try? FileManager.default.removeItem(at: $0) }
    }
}

final class HistoryWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate {
    private let store: HistoryStore
    private let onOpen: (CGImage) -> Void
    private let table = NSTableView()
    private var urls: [URL] = []

    init(store: HistoryStore, onOpen: @escaping (CGImage) -> Void) {
        self.store = store
        self.onOpen = onOpen
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 620, height: 440),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.text(.historyTitle)
        window.center()
        super.init(window: window)
        buildInterface()
    }

    required init?(coder: NSCoder) { nil }

    override func showWindow(_ sender: Any?) {
        urls = store.items()
        table.reloadData()
        super.showWindow(sender)
        NSApplication.shared.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func numberOfRows(in tableView: NSTableView) -> Int { urls.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = NSTableCellView()
        let field = NSTextField(labelWithString: urls[row].lastPathComponent)
        field.frame = CGRect(x: 8, y: 4, width: 500, height: 22)
        cell.addSubview(field)
        return cell
    }

    @objc private func openSelected() {
        let row = table.selectedRow
        guard row >= 0, row < urls.count, let image = store.image(at: urls[row]) else { return }
        onOpen(image)
    }

    @objc private func clearHistory() {
        let alert = NSAlert()
        alert.messageText = L10n.text(.clearHistoryQuestion)
        alert.addButton(withTitle: L10n.text(.clear))
        alert.addButton(withTitle: L10n.text(.cancel))
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        store.clear()
        urls = []
        table.reloadData()
    }

    private func buildInterface() {
        guard let content = window?.contentView else { return }
        let scroll = NSScrollView(frame: CGRect(x: 12, y: 52, width: 596, height: 376))
        scroll.autoresizingMask = [.width, .height]
        scroll.hasVerticalScroller = true
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("capture"))
        column.title = L10n.text(.recentCaptures)
        column.width = 580
        table.addTableColumn(column)
        table.headerView = nil
        table.rowHeight = 30
        table.delegate = self
        table.dataSource = self
        table.target = self
        table.doubleAction = #selector(openSelected)
        scroll.documentView = table
        content.addSubview(scroll)

        let open = NSButton(title: L10n.text(.open), target: self, action: #selector(openSelected))
        open.frame = CGRect(x: 12, y: 12, width: 80, height: 30)
        content.addSubview(open)
        let clear = NSButton(title: L10n.text(.clearHistory), target: self, action: #selector(clearHistory))
        clear.frame = CGRect(x: 98, y: 12, width: 110, height: 30)
        content.addSubview(clear)
    }
}
