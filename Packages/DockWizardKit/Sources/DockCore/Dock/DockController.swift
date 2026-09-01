import Foundation

/// Reads and writes the Dock.
public struct DockController: Sendable {
    public let store: PreferencesStore
    public let restarter: DockRestarter
    public let backups: DockBackupStore?

    public init(
        store: PreferencesStore = CFPreferencesStore.dock,
        restarter: DockRestarter = ProcessDockRestarter(),
        backups: DockBackupStore? = DockBackupStore.defaultStore()
    ) {
        self.store = store
        self.restarter = restarter
        self.backups = backups
    }

    /// The Dock as it currently stands.
    public func read() -> DockState {
        DockState(
            apps: DockTileCodec.decodeSection(store.value(forKey: DockKeys.persistentApps)),
            others: DockTileCodec.decodeSection(store.value(forKey: DockKeys.persistentOthers)),
            settings: DockSettingsCodec.decode(from: store)
        )
    }

    /// Replaces the Dock with `state`.
    ///
    /// Both tile arrays are written in full — apply is replace-only. Settings are partial:
    /// only keys present in `state.settings` are written.
    @discardableResult
    public func apply(_ state: DockState, options: ApplyOptions = ApplyOptions()) throws -> ApplyResult {
        let backup = options.createBackup ? try backups?.snapshot(of: store) : nil

        var changes: [String: PlistValue?] = [
            DockKeys.persistentApps: DockTileCodec.encodeSection(state.apps),
            DockKeys.persistentOthers: DockTileCodec.encodeSection(state.others),
        ]
        for (key, value) in DockSettingsCodec.encode(state.settings) {
            changes[key] = value
        }
        try store.setValues(changes)

        if options.restartDock {
            try restarter.restart()
        }
        return ApplyResult(backup: backup)
    }

    /// Restores a snapshot and restarts the Dock.
    public func restore(_ backup: DockBackup, options: ApplyOptions = ApplyOptions()) throws {
        guard let backups else { throw DockBackupError.notFound(backup.name) }
        try backups.restore(backup, to: store)
        if options.restartDock {
            try restarter.restart()
        }
    }

    public struct ApplyOptions: Sendable {
        public var createBackup: Bool
        public var restartDock: Bool

        public init(createBackup: Bool = true, restartDock: Bool = true) {
            self.createBackup = createBackup
            self.restartDock = restartDock
        }
    }

    public struct ApplyResult: Sendable {
        public var backup: DockBackup?
    }
}
