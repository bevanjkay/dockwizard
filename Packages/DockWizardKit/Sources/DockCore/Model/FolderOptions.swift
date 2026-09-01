import Foundation

/// How a `directory-tile` presents itself in the Dock.
///
/// The underlying plist stores undocumented integers; the mappings below follow the
/// long-standing convention also used by `dockutil`. See `AGENTS.md` for verification notes.
public struct FolderOptions: Codable, Sendable, Equatable, Hashable {
    public var showAs: ShowAs?
    public var displayAs: DisplayAs?
    public var arrangement: Arrangement?
    /// `nil` means automatic (the plist's magic `-1`).
    public var itemSize: Int?

    public init(
        showAs: ShowAs? = nil,
        displayAs: DisplayAs? = nil,
        arrangement: Arrangement? = nil,
        itemSize: Int? = nil
    ) {
        self.showAs = showAs
        self.displayAs = displayAs
        self.arrangement = arrangement
        self.itemSize = itemSize
    }

    public enum ShowAs: String, Codable, Sendable, CaseIterable {
        case automatic, fan, grid, list

        public var plistValue: Int {
            switch self {
            case .automatic: 0
            case .fan: 1
            case .grid: 2
            case .list: 3
            }
        }

        public init?(plistValue: Int) {
            guard let match = Self.allCases.first(where: { $0.plistValue == plistValue }) else { return nil }
            self = match
        }
    }

    public enum DisplayAs: String, Codable, Sendable, CaseIterable {
        case stack, folder

        public var plistValue: Int {
            switch self {
            case .stack: 0
            case .folder: 1
            }
        }

        public init?(plistValue: Int) {
            guard let match = Self.allCases.first(where: { $0.plistValue == plistValue }) else { return nil }
            self = match
        }
    }

    public enum Arrangement: String, Codable, Sendable, CaseIterable {
        case name, dateAdded, dateModified, dateCreated, kind

        public var plistValue: Int {
            switch self {
            case .name: 1
            case .dateAdded: 2
            case .dateModified: 3
            case .dateCreated: 4
            case .kind: 5
            }
        }

        public init?(plistValue: Int) {
            guard let match = Self.allCases.first(where: { $0.plistValue == plistValue }) else { return nil }
            self = match
        }
    }

    /// The plist's automatic sentinel for `preferreditemsize`.
    public static let automaticItemSize = -1
}
