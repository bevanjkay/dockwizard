import Foundation

/// A complete snapshot of the parts of the Dock that DockWizard manages.
public struct DockState: Codable, Sendable, Equatable {
    /// `persistent-apps` — the section left of (or above) the divider.
    public var apps: [DockTile]
    /// `persistent-others` — folders, files and links right of (or below) the divider.
    public var others: [DockTile]
    public var settings: DockSettings

    public init(apps: [DockTile] = [], others: [DockTile] = [], settings: DockSettings = DockSettings()) {
        self.apps = apps
        self.others = others
        self.settings = settings
    }

    /// Which of the Dock's two arrays a tile belongs to.
    public enum Section: String, Codable, Sendable, CaseIterable {
        case apps
        case others

        public var preferencesKey: String {
            switch self {
            case .apps: DockKeys.persistentApps
            case .others: DockKeys.persistentOthers
            }
        }
    }

    public subscript(section: Section) -> [DockTile] {
        get {
            switch section {
            case .apps: apps
            case .others: others
            }
        }
        set {
            switch section {
            case .apps: apps = newValue
            case .others: others = newValue
            }
        }
    }
}
