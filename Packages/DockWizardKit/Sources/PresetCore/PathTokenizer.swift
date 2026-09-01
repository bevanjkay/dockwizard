import DockCore
import Foundation

/// Rewrites the home directory to and from `~` so presets survive a different username.
public enum PathTokenizer {
    public static func tokenize(_ path: String, home: String = NSHomeDirectory()) -> String {
        let home = normalized(home)
        guard !home.isEmpty else { return path }
        if path == home { return "~" }
        guard path.hasPrefix(home + "/") else { return path }
        return "~" + path.dropFirst(home.count)
    }

    public static func expand(_ path: String, home: String = NSHomeDirectory()) -> String {
        guard path == "~" || path.hasPrefix("~/") else { return path }
        let home = normalized(home)
        if path == "~" { return home }
        return home + path.dropFirst(1)
    }

    public static func tokenize(_ tile: DockTile, home: String = NSHomeDirectory()) -> DockTile {
        guard let path = tile.path else { return tile }
        var copy = tile
        copy.path = tokenize(path, home: home)
        return copy
    }

    public static func expand(_ tile: DockTile, home: String = NSHomeDirectory()) -> DockTile {
        guard let path = tile.path else { return tile }
        var copy = tile
        copy.path = expand(path, home: home)
        return copy
    }

    private static func normalized(_ home: String) -> String {
        home.count > 1 && home.hasSuffix("/") ? String(home.dropLast()) : home
    }
}
