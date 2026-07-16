import AppKit
import CoreGraphics
import Foundation
import SnapSailCore
import UniformTypeIdentifiers

enum ImageUtilities {
    static func stack(images: [CGImage], spacing: Int = 16) -> CGImage? {
        guard let first = images.first else { return nil }
        if images.count == 1 { return first }

        let width = images.map(\.width).max() ?? first.width
        let height = images.reduce(0) { $0 + $1.height } + spacing * (images.count - 1)
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        var y = height
        for image in images {
            y -= image.height
            let x = (width - image.width) / 2
            context.draw(image, in: CGRect(x: x, y: y, width: image.width, height: image.height))
            y -= spacing
        }
        return context.makeImage()
    }
}

enum ImageExporter {
    static func data(for image: CGImage, format: CaptureOutputFormat, quality: Double) -> Data? {
        let bitmap = NSBitmapImageRep(cgImage: image)
        switch format {
        case .png:
            return bitmap.representation(using: .png, properties: [:])
        case .jpeg:
            return bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
        }
    }

    static func copyToPasteboard(_ image: CGImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))])
    }

    @discardableResult
    static func save(_ image: CGImage, to directory: URL, preferences: AppPreferences) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let name = FilenameTemplate.filename(
            prefix: preferences.filenamePrefix,
            fileExtension: preferences.outputFormat.fileExtension
        )
        let url = uniqueURL(directory.appendingPathComponent(name))
        guard let data = data(for: image, format: preferences.outputFormat, quality: preferences.jpegQuality) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: url, options: .atomic)
        return url
    }

    static func presentSavePanel(for image: CGImage, preferences: AppPreferences, window: NSWindow?) {
        let panel = NSSavePanel()
        panel.directoryURL = preferences.saveDirectory
        panel.nameFieldStringValue = FilenameTemplate.filename(
            prefix: preferences.filenamePrefix,
            fileExtension: preferences.outputFormat.fileExtension
        )
        panel.allowedContentTypes = [preferences.outputFormat == .png ? .png : .jpeg]
        panel.canCreateDirectories = true
        let completion: (NSApplication.ModalResponse) -> Void = { response in
            guard response == .OK, let url = panel.url,
                  let data = data(for: image, format: preferences.outputFormat, quality: preferences.jpegQuality) else { return }
            do {
                try data.write(to: url, options: .atomic)
                preferences.saveDirectory = url.deletingLastPathComponent()
            } catch {
                NSAlert(error: error).runModal()
            }
        }
        if let window { panel.beginSheetModal(for: window, completionHandler: completion) }
        else { completion(panel.runModal()) }
    }

    private static func uniqueURL(_ proposed: URL) -> URL {
        guard FileManager.default.fileExists(atPath: proposed.path) else { return proposed }
        let stem = proposed.deletingPathExtension().lastPathComponent
        let ext = proposed.pathExtension
        let directory = proposed.deletingLastPathComponent()
        var index = 2
        while true {
            let candidate = directory.appendingPathComponent("\(stem)-\(index).\(ext)")
            if !FileManager.default.fileExists(atPath: candidate.path) { return candidate }
            index += 1
        }
    }
}
