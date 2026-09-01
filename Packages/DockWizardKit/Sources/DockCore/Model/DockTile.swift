import Foundation

/// A single Dock tile.
///
/// This is both the in-memory model and the on-disk preset representation: `Codable`
/// conformance produces the JSON shape documented in the README. Paths are stored
/// verbatim here; `PresetCore` tokenises `$HOME` on the way out and expands on the way in.
public struct DockTile: Codable, Sendable, Equatable, Hashable {
    public var kind: TileKind
    /// Filesystem path for `.app`, `.file` and `.folder` tiles.
    public var path: String?
    /// Web address for `.url` tiles.
    public var url: String?
    public var label: String?
    /// Recorded on export to make resolution portable. Never written back to the Dock —
    /// the Dock derives `bundle-identifier` itself from the path.
    public var bundleID: String?
    public var folder: FolderOptions?

    public init(
        kind: TileKind,
        path: String? = nil,
        url: String? = nil,
        label: String? = nil,
        bundleID: String? = nil,
        folder: FolderOptions? = nil
    ) {
        self.kind = kind
        self.path = path
        self.url = url
        self.label = label
        self.bundleID = bundleID
        self.folder = folder
    }

    private enum CodingKeys: String, CodingKey {
        case kind = "type"
        case path, url, label
        case bundleID = "bundleId"
        case folder
    }

    public static func app(path: String, label: String? = nil, bundleID: String? = nil) -> DockTile {
        DockTile(kind: .app, path: path, label: label, bundleID: bundleID)
    }

    public static func spacer(_ kind: TileKind = .spacer) -> DockTile {
        DockTile(kind: kind)
    }

    /// A short human description used in diffs and CLI listings.
    public var displayName: String {
        if let label, !label.isEmpty {
            return label
        }
        switch kind {
        case .spacer: return "— spacer —"
        case .smallSpacer: return "— small spacer —"
        case .flexSpacer: return "— flexible spacer —"
        case .url: return url ?? "URL"
        case .app, .file, .folder:
            guard let path else { return kind.rawValue }
            return (path as NSString).lastPathComponent
        }
    }
}
