import DockCore
import Foundation
import PresetCore

enum Output {
    static func error(_ message: String) {
        write("dockwizard: \(message)\n", to: FileHandle.standardError)
    }

    static func warning(_ message: String) {
        write("warning: \(message)\n", to: FileHandle.standardError)
    }

    static func note(_ message: String) {
        print(message)
    }

    private static func write(_ text: String, to handle: FileHandle) {
        guard let data = text.data(using: .utf8) else { return }
        handle.write(data)
    }

    static func describe(_ tile: DockTile, index: Int) -> String {
        let position = String(index).leftPadded(to: 3)
        let kind = tile.kind.rawValue.rightPadded(to: 12)
        var line = "\(position)  \(kind)\(tile.displayName)"
        if let path = tile.path, !tile.kind.isSpacer {
            line += "  (\(path))"
        } else if let url = tile.url {
            line += "  (\(url))"
        }
        return line
    }

    /// Renders a diff for `--dry-run` and `diff`, in the same shape the GUI preview shows.
    static func render(_ diff: DockDiff) -> String {
        guard !diff.isEmpty else { return "No changes." }
        var lines: [String] = []
        for section in diff.sections where !section.isEmpty {
            lines.append("\(section.section.rawValue):")
            for tile in section.removed { lines.append("  - \(tile.displayName)") }
            for tile in section.added { lines.append("  + \(tile.displayName)") }
            if section.reordered { lines.append("  ~ order changes") }
        }
        if !diff.settings.isEmpty {
            lines.append("settings:")
            for change in diff.settings {
                lines.append("  ~ \(change.key): \(change.before ?? "unset") -> \(change.after)")
            }
        }
        return lines.joined(separator: "\n")
    }

    static func report(missing: [MissingTile]) {
        guard !missing.isEmpty else { return }
        let noun = missing.count == 1 ? "item" : "items"
        warning("\(missing.count) \(noun) could not be placed and will be skipped:")
        for item in missing {
            warning("  \(item.tile.displayName) — \(item.reason.explanation)")
        }
    }
}

private extension String {
    func leftPadded(to width: Int) -> String {
        count >= width ? self : String(repeating: " ", count: width - count) + self
    }

    func rightPadded(to width: Int) -> String {
        count >= width ? self + " " : self + String(repeating: " ", count: width - count)
    }
}
