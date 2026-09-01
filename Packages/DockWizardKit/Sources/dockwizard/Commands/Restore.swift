import ArgumentParser
import DockCore
import Foundation

struct Restore: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Roll the Dock back to a snapshot taken before an earlier apply."
    )

    @Argument(help: "Snapshot name or path. Defaults to the most recent.")
    var backup: String?

    @Flag(name: .long, help: "List available snapshots instead of restoring one.")
    var list = false

    func run() throws {
        let store = DockBackupStore.defaultStore()

        if list {
            let snapshots = try store.list()
            guard !snapshots.isEmpty else {
                Output.note("No snapshots in \(store.directory.path)")
                return
            }
            for snapshot in snapshots {
                Output.note(snapshot.name)
            }
            return
        }

        let snapshot: DockBackup?
        if let backup {
            snapshot = try store.backup(named: backup)
        } else {
            snapshot = try store.mostRecent()
        }
        guard let snapshot else {
            throw DockBackupError.notFound(backup ?? "most recent")
        }

        try DockController(backups: store).restore(snapshot)
        Output.note("Restored \(snapshot.name)")
    }
}
