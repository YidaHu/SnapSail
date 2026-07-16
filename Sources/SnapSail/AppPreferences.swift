import AppKit
import Foundation

enum CaptureOutputFormat: String, CaseIterable {
    case png
    case jpeg

    var fileExtension: String { self == .png ? "png" : "jpg" }
}

final class AppPreferences {
    static let shared = AppPreferences()

    private enum Key {
        static let outputFormat = "outputFormat"
        static let jpegQuality = "jpegQuality"
        static let includeWindowShadow = "includeWindowShadow"
        static let playSound = "playSound"
        static let showNotification = "showNotification"
        static let copyAfterCapture = "copyAfterCapture"
        static let saveAfterCapture = "saveAfterCapture"
        static let saveDirectory = "saveDirectory"
        static let filenamePrefix = "filenamePrefix"
        static let historyEnabled = "historyEnabled"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.outputFormat: CaptureOutputFormat.png.rawValue,
            Key.jpegQuality: 0.9,
            Key.includeWindowShadow: true,
            Key.playSound: true,
            Key.showNotification: true,
            Key.copyAfterCapture: false,
            Key.saveAfterCapture: false,
            Key.saveDirectory: FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? NSHomeDirectory(),
            Key.filenamePrefix: "SnapSail",
            Key.historyEnabled: true
        ])
    }

    var outputFormat: CaptureOutputFormat {
        get { CaptureOutputFormat(rawValue: defaults.string(forKey: Key.outputFormat) ?? "png") ?? .png }
        set { defaults.set(newValue.rawValue, forKey: Key.outputFormat) }
    }

    var jpegQuality: Double {
        get { defaults.double(forKey: Key.jpegQuality) }
        set { defaults.set(max(0.1, min(1, newValue)), forKey: Key.jpegQuality) }
    }

    var includeWindowShadow: Bool {
        get { defaults.bool(forKey: Key.includeWindowShadow) }
        set { defaults.set(newValue, forKey: Key.includeWindowShadow) }
    }

    var playSound: Bool {
        get { defaults.bool(forKey: Key.playSound) }
        set { defaults.set(newValue, forKey: Key.playSound) }
    }

    var showNotification: Bool {
        get { defaults.bool(forKey: Key.showNotification) }
        set { defaults.set(newValue, forKey: Key.showNotification) }
    }

    var copyAfterCapture: Bool {
        get { defaults.bool(forKey: Key.copyAfterCapture) }
        set { defaults.set(newValue, forKey: Key.copyAfterCapture) }
    }

    var saveAfterCapture: Bool {
        get { defaults.bool(forKey: Key.saveAfterCapture) }
        set { defaults.set(newValue, forKey: Key.saveAfterCapture) }
    }

    var saveDirectory: URL {
        get { URL(fileURLWithPath: defaults.string(forKey: Key.saveDirectory) ?? NSHomeDirectory(), isDirectory: true) }
        set { defaults.set(newValue.path, forKey: Key.saveDirectory) }
    }

    var filenamePrefix: String {
        get { defaults.string(forKey: Key.filenamePrefix) ?? "SnapSail" }
        set { defaults.set(newValue, forKey: Key.filenamePrefix) }
    }

    var historyEnabled: Bool {
        get { defaults.bool(forKey: Key.historyEnabled) }
        set { defaults.set(newValue, forKey: Key.historyEnabled) }
    }
}
