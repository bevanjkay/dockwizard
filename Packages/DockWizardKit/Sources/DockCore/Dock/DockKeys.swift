import Foundation

/// Preference keys used by `com.apple.dock`.
public enum DockKeys {
    public static let domain = "com.apple.dock"

    public static let persistentApps = "persistent-apps"
    public static let persistentOthers = "persistent-others"

    public static let orientation = "orientation"
    public static let tileSize = "tilesize"
    public static let largeSize = "largesize"
    public static let magnification = "magnification"
    public static let autohide = "autohide"
    public static let autohideDelay = "autohide-delay"
    public static let autohideTimeModifier = "autohide-time-modifier"
    public static let minimizeEffect = "mineffect"
    public static let minimizeToApplication = "minimize-to-application"
    public static let showRecents = "show-recents"
    public static let showHidden = "showhidden"
    public static let staticOnly = "static-only"
    public static let launchAnimation = "launchanim"

    /// Keys within a tile dictionary.
    public enum Tile {
        public static let tileType = "tile-type"
        public static let tileData = "tile-data"
        public static let fileLabel = "file-label"
        public static let label = "label"
        public static let fileData = "file-data"
        public static let url = "url"
        public static let bundleIdentifier = "bundle-identifier"
        public static let urlString = "_CFURLString"
        public static let urlStringType = "_CFURLStringType"
        public static let showAs = "showas"
        public static let displayAs = "displayas"
        public static let arrangement = "arrangement"
        public static let preferredItemSize = "preferreditemsize"
    }

    /// `_CFURLStringType` value for an absolute URL string.
    public static let absoluteURLStringType = 15
}
