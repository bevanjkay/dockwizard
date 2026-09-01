import Foundation

/// A saved snapshot of the whole `com.apple.dock` domain.
public struct DockBackup: Sendable, Equatable, Identifiable {
    public let url: URL
    public let createdAt: Date

    public var id: URL {
        url
    }

    public var name: String {
        url.deletingPathExtension().lastPathComponent
    }

    public init(url: URL, createdAt: Date) {
        self.url = url
        self.createdAt = createdAt
    }
}

/// Stores raw snapshots of the Dock's preference domain.
///
/// Snapshots are the full domain, not a preset: a preset only carries what DockWizard models,
/// whereas a rollback has to restore keys the schema knows nothing about. Presets are for
/// sharing; backups are for safety.
public struct DockBackupStore: Sendable {
    public let directory: URL
    public let limit: Int

    public init(directory: URL, limit: Int = 10) {
        self.directory = directory
        self.limit = limit
    }

    public static func defaultStore(limit: Int = 10) -> DockBackupStore {
        DockBackupStore(directory: ApplicationPaths.backupsDirectory, limit: limit)
    }

    /// Snapshot filenames sort lexicographically in chronological order, which is what
    /// `list()` relies on to find the most recent one.
    private static func timestamp(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH-mm-ss'Z'"
        return formatter.string(from: date)
    }

    /// Writes the current contents of `store` to a timestamped plist and prunes old snapshots.
    @discardableResult
    public func snapshot(of store: PreferencesStore, at date: Date = Date()) throws -> DockBackup {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("\(Self.timestamp(for: date)).plist")
        let values = store.allValues().mapValues(\.propertyListObject)
        let data = try PropertyListSerialization.data(
            fromPropertyList: values,
            format: .binary,
            options: 0
        )
        try data.write(to: url, options: .atomic)
        try prune()
        return DockBackup(url: url, createdAt: date)
    }

    /// Snapshots, newest first.
    public func list() throws -> [DockBackup] {
        let manager = FileManager.default
        guard manager.fileExists(atPath: directory.path) else { return [] }
        let contents = try manager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        return contents
            .filter { $0.pathExtension == "plist" }
            .map { url in
                let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
                    .contentModificationDate ?? .distantPast
                return DockBackup(url: url, createdAt: modified)
            }
            .sorted { $0.url.lastPathComponent > $1.url.lastPathComponent }
    }

    public func mostRecent() throws -> DockBackup? {
        try list().first
    }

    /// Resolves a user-supplied backup reference: a full path, or a snapshot name.
    public func backup(named name: String) throws -> DockBackup? {
        if name.contains("/") {
            let url = URL(fileURLWithPath: (name as NSString).expandingTildeInPath)
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            return DockBackup(url: url, createdAt: .distantPast)
        }
        return try list().first { $0.name == name || $0.url.lastPathComponent == name }
    }

    /// Restores a snapshot, removing any keys added since it was taken.
    public func restore(_ backup: DockBackup, to store: PreferencesStore) throws {
        let data = try Data(contentsOf: backup.url)
        guard let object = try PropertyListSerialization.propertyList(
            from: data, options: [], format: nil
        ) as? [String: Any] else {
            throw DockBackupError.unreadable(backup.url)
        }
        var restored: [String: PlistValue] = [:]
        for (key, value) in object {
            if let converted = PlistValue(propertyList: value) {
                restored[key] = converted
            }
        }
        var changes: [String: PlistValue?] = restored.mapValues { Optional($0) }
        for key in store.allValues().keys where restored[key] == nil {
            changes[key] = PlistValue?.none
        }
        try store.setValues(changes)
    }

    private func prune() throws {
        let snapshots = try list()
        guard snapshots.count > limit else { return }
        for snapshot in snapshots.dropFirst(limit) {
            try? FileManager.default.removeItem(at: snapshot.url)
        }
    }
}

public enum DockBackupError: Error, LocalizedError {
    case unreadable(URL)
    case notFound(String)

    public var errorDescription: String? {
        switch self {
        case let .unreadable(url): "Could not read the backup at \(url.path)."
        case let .notFound(name): "No backup named \(name)."
        }
    }
}
