import DockCore
import Foundation

/// A directory of preset files.
///
/// The directory defaults to Application Support but is overridable in Settings and by
/// `DOCKWIZARD_PRESETS_DIR`, so it can point straight at a dotfiles repository.
public struct PresetLibrary: Sendable {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public static func `default`(override: String? = nil) -> PresetLibrary {
        PresetLibrary(directory: ApplicationPaths.presetsDirectory(override: override))
    }

    public struct Entry: Sendable, Equatable, Identifiable {
        public var name: String
        public var url: URL
        public var id: URL {
            url
        }

        public init(name: String, url: URL) {
            self.name = name
            self.url = url
        }
    }

    public func entries() throws -> [Entry] {
        let manager = FileManager.default
        guard manager.fileExists(atPath: directory.path) else { return [] }
        let contents = try manager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        )
        return contents
            .filter { $0.pathExtension.lowercased() == "json" }
            .map { Entry(name: $0.deletingPathExtension().lastPathComponent, url: $0) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Resolves a CLI argument that may be a preset name or a filesystem path.
    public func url(for reference: String) throws -> URL {
        if reference.contains("/") || reference.lowercased().hasSuffix(".json") {
            let expanded = (reference as NSString).expandingTildeInPath
            let url = URL(fileURLWithPath: expanded)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        let matches = try entries().filter { $0.name == reference }
        switch matches.count {
        case 0: throw PresetError.presetNotFound(reference)
        case 1: return matches[0].url
        default: throw PresetError.ambiguousName(reference)
        }
    }

    public func load(_ reference: String) throws -> PresetDocument.LoadResult {
        try PresetDocument.load(from: url(for: reference))
    }

    @discardableResult
    public func save(_ preset: Preset, as name: String) throws -> URL {
        let url = directory.appendingPathComponent("\(Self.slug(name)).json")
        try PresetDocument.write(preset, to: url)
        return url
    }

    public func delete(_ entry: Entry) throws {
        try FileManager.default.removeItem(at: entry.url)
    }

    /// A filename-safe form of a preset name.
    public static func slug(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ "))
        let cleaned = name.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let collapsed = String(cleaned)
            .split(separator: " ", omittingEmptySubsequences: true)
            .joined(separator: "-")
            .lowercased()
        return collapsed.isEmpty ? "preset" : collapsed
    }
}
