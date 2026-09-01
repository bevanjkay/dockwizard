import Foundation

/// A human-readable summary of the change applying a state would make.
///
/// One diff engine serves both front ends: the GUI preview sheet and the CLI's `--dry-run`.
public struct DockDiff: Sendable, Equatable {
    public var sections: [SectionDiff]
    public var settings: [SettingChange]

    public init(sections: [SectionDiff] = [], settings: [SettingChange] = []) {
        self.sections = sections
        self.settings = settings
    }

    public var isEmpty: Bool {
        settings.isEmpty && sections.allSatisfy(\.isEmpty)
    }

    public struct SectionDiff: Sendable, Equatable {
        public var section: DockState.Section
        public var added: [DockTile]
        public var removed: [DockTile]
        /// True when the tiles common to both states appear in a different order.
        public var reordered: Bool

        public init(
            section: DockState.Section,
            added: [DockTile] = [],
            removed: [DockTile] = [],
            reordered: Bool = false
        ) {
            self.section = section
            self.added = added
            self.removed = removed
            self.reordered = reordered
        }

        public var isEmpty: Bool { added.isEmpty && removed.isEmpty && !reordered }
    }

    public struct SettingChange: Sendable, Equatable {
        public var key: String
        public var before: String?
        public var after: String

        public init(key: String, before: String?, after: String) {
            self.key = key
            self.before = before
            self.after = after
        }
    }

    /// Computes what would change moving from `current` to `target`.
    public static func between(current: DockState, target: DockState) -> DockDiff {
        let sections = DockState.Section.allCases.map { section in
            diffSection(section, current: current[section], target: target[section])
        }
        return DockDiff(sections: sections, settings: settingChanges(current: current, target: target))
    }

    private static func diffSection(
        _ section: DockState.Section,
        current: [DockTile],
        target: [DockTile]
    ) -> SectionDiff {
        var remaining = current.map(identity)
        var added: [DockTile] = []
        var commonInTarget: [String] = []

        for tile in target {
            let key = identity(tile)
            if let index = remaining.firstIndex(of: key) {
                remaining.remove(at: index)
                commonInTarget.append(key)
            } else {
                added.append(tile)
            }
        }

        var removed: [DockTile] = []
        var leftovers = remaining
        for tile in current {
            let key = identity(tile)
            if let index = leftovers.firstIndex(of: key) {
                leftovers.remove(at: index)
                removed.append(tile)
            }
        }

        let removedKeys = removed.map(identity)
        var stillPresent = removedKeys
        let commonInCurrent = current.map(identity).filter { key in
            if let index = stillPresent.firstIndex(of: key) {
                stillPresent.remove(at: index)
                return false
            }
            return true
        }

        return SectionDiff(
            section: section,
            added: added,
            removed: removed,
            reordered: commonInCurrent != commonInTarget
        )
    }

    /// Tiles are matched on what they point at, not on their label — renaming a tile is not
    /// an add plus a remove.
    private static func identity(_ tile: DockTile) -> String {
        switch tile.kind {
        case .spacer, .smallSpacer, .flexSpacer: tile.kind.rawValue
        case .url: "url:\(tile.url ?? "")"
        case .app, .file, .folder: "\(tile.kind.rawValue):\(tile.path ?? "")"
        }
    }

    private static func settingChanges(current: DockState, target: DockState) -> [SettingChange] {
        let before = DockSettingsCodec.encode(current.settings)
        let after = DockSettingsCodec.encode(target.settings)
        return after.keys.sorted().compactMap { key in
            guard let newValue = after[key] else { return nil }
            let oldValue = before[key]
            guard oldValue != newValue else { return nil }
            return SettingChange(
                key: key,
                before: oldValue.map(describe),
                after: describe(newValue)
            )
        }
    }

    private static func describe(_ value: PlistValue) -> String {
        switch value {
        case let .bool(flag): flag ? "true" : "false"
        case let .int(number): String(number)
        case let .double(number): number == number.rounded() ? String(Int(number)) : String(number)
        case let .string(text): text
        default: "…"
        }
    }
}
