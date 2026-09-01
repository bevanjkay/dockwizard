import Foundation

/// The kinds of tile DockWizard models.
///
/// The Dock itself distinguishes tiles by a `tile-type` string; apps and plain files share
/// `file-tile` and are told apart by whether the path is an application bundle.
public enum TileKind: String, Codable, Sendable, CaseIterable {
    case app
    case file
    case folder
    case url
    case spacer
    case smallSpacer
    case flexSpacer

    /// The `tile-type` value the Dock expects in its preferences.
    public var dockTileType: String {
        switch self {
        case .app, .file: "file-tile"
        case .folder: "directory-tile"
        case .url: "url-tile"
        case .spacer: "spacer-tile"
        case .smallSpacer: "small-spacer-tile"
        case .flexSpacer: "flex-spacer-tile"
        }
    }

    public var isSpacer: Bool {
        switch self {
        case .spacer, .smallSpacer, .flexSpacer: true
        case .app, .file, .folder, .url: false
        }
    }

    /// Maps a Dock `tile-type` back to a kind. `file-tile` needs the path to disambiguate
    /// an application bundle from a plain file.
    public static func from(dockTileType: String, path: String?) -> TileKind? {
        switch dockTileType {
        case "file-tile":
            let isBundle = (path.map { $0.hasSuffix(".app") || $0.hasSuffix(".app/") }) ?? false
            return isBundle ? .app : .file
        case "directory-tile": return .folder
        case "url-tile": return .url
        case "spacer-tile": return .spacer
        case "small-spacer-tile": return .smallSpacer
        case "flex-spacer-tile": return .flexSpacer
        default: return nil
        }
    }
}
