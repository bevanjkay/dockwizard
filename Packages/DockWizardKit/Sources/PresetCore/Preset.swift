import DockCore
import Foundation

/// A portable Dock preset.
///
/// Paths inside a preset are tokenised: `$HOME` is written as `~` so a preset committed to a
/// dotfiles repository works on a machine with a different username.
public struct Preset: Codable, Sendable, Equatable {
    /// The only schema version this build writes.
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var generator: String?
    public var name: String?
    public var summary: String?
    public var apps: [DockTile]
    public var others: [DockTile]
    /// Optional and partial: absent keys leave the corresponding Dock setting untouched.
    public var settings: DockSettings?

    public init(
        schemaVersion: Int = Preset.currentSchemaVersion,
        generator: String? = nil,
        name: String? = nil,
        summary: String? = nil,
        apps: [DockTile] = [],
        others: [DockTile] = [],
        settings: DockSettings? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.generator = generator
        self.name = name
        self.summary = summary
        self.apps = apps
        self.others = others
        self.settings = settings
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, generator, name
        case summary = "description"
        case apps, others, settings
    }

    /// Keys understood at the top level of a preset document.
    static let knownKeys: Set<String> = ["schemaVersion", "generator", "name", "description", "apps", "others", "settings"]
}

public extension Preset {
    /// Captures a Dock snapshot as a preset, tokenising paths.
    static func capturing(
        _ state: DockState,
        name: String? = nil,
        summary: String? = nil,
        includeSettings: Bool = true,
        generator: String? = PresetGenerator.current,
        home: String = NSHomeDirectory()
    ) -> Preset {
        Preset(
            generator: generator,
            name: name,
            summary: summary,
            apps: state.apps.map { PathTokenizer.tokenize($0, home: home) },
            others: state.others.map { PathTokenizer.tokenize($0, home: home) },
            settings: includeSettings ? state.settings : nil
        )
    }

    /// The preset's tiles with `~` expanded, before app resolution.
    func expandedState(home: String = NSHomeDirectory()) -> DockState {
        DockState(
            apps: apps.map { PathTokenizer.expand($0, home: home) },
            others: others.map { PathTokenizer.expand($0, home: home) },
            settings: settings ?? DockSettings()
        )
    }
}

/// Identifies the build that wrote a preset.
public enum PresetGenerator {
    public static let version = "0.2.0"
    public static let current = "dockwizard/\(version)"
}
