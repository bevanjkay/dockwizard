import DockCore
import Foundation
import Testing

struct DockBackupTests {
    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("dockwizard-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func restoringPutsBackKeysAndRemovesOnesAddedSince() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = InMemoryPreferencesStore(initialValues: [
            "orientation": .string("bottom"),
            "tilesize": .double(48),
        ])
        let backups = DockBackupStore(directory: directory)
        let snapshot = try backups.snapshot(of: store)

        try store.setValues([
            "tilesize": .double(64),
            "autohide": .bool(true),
            "orientation": nil,
        ])
        try backups.restore(snapshot, to: store)

        #expect(store.value(forKey: "tilesize")?.doubleValue == 48)
        #expect(store.value(forKey: "orientation")?.stringValue == "bottom")
        #expect(store.value(forKey: "autohide") == nil)
    }

    @Test func keepsOnlyTheMostRecentSnapshots() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = InMemoryPreferencesStore(initialValues: ["tilesize": .double(48)])
        let backups = DockBackupStore(directory: directory, limit: 3)
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        for offset in 0 ..< 6 {
            try backups.snapshot(of: store, at: start.addingTimeInterval(Double(offset) * 60))
        }

        let snapshots = try backups.list()
        #expect(snapshots.count == 3)
        #expect(try backups.mostRecent()?.name == snapshots.first?.name)
    }

    @Test func snapshotNamesSortChronologically() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = InMemoryPreferencesStore(initialValues: ["tilesize": .double(48)])
        let backups = DockBackupStore(directory: directory)
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let older = try backups.snapshot(of: store, at: start)
        let newer = try backups.snapshot(of: store, at: start.addingTimeInterval(3600))

        // Compared by filename: enumerating the directory resolves the /var symlink.
        #expect(try backups.mostRecent()?.name == newer.name)
        #expect(older.name < newer.name)
    }
}
