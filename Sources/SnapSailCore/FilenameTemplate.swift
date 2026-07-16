import Foundation

public enum FilenameTemplate {
    public static func filename(
        prefix: String,
        date: Date = Date(),
        fileExtension: String,
        timeZone: TimeZone = .current
    ) -> String {
        let cleaned = prefix
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        let safePrefix = cleaned.isEmpty ? "SnapSail" : cleaned

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return "\(safePrefix)-\(formatter.string(from: date)).\(fileExtension.lowercased())"
    }
}
