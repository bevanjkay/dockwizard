import DockCore
import Foundation
import Testing

/// Exercises the real `CFPreferences` implementation against a throwaway domain.
///
/// The unit tests use an in-memory store, which proves the model but not the plumbing. The
/// part most likely to break is round-tripping the Dock's nested array-of-dictionaries
/// through `CFPropertyList`, and that needs a real preferences domain — but never
/// `com.apple.dock`. Opt in with `DOCKWIZARD_INTEGRATION=1`; CI always sets it.
struct PreferencesIntegrationTests {
    /// Swift Testing runs tests in parallel, so each one needs its own domain — sharing a
    /// single scratch domain had one test wiping another's keys mid-run.
    private static let stateDomain = "me.bevankay.dockwizard.test.state"
    private static let settingsDomain = "me.bevankay.dockwizard.test.settings"

    private var isEnabled: Bool {
        ProcessInfo.processInfo.environment["DOCKWIZARD_INTEGRATION"] == "1"
    }

    private func clean(_ store: PreferencesStore) throws {
        try store.setValues(store.allValues().keys.reduce(into: [:]) { $0[$1] = PlistValue?.none })
    }

    @Test func roundTripsAFullDockStateThroughRealPreferences() throws {
        try withKnownIssue("requires DOCKWIZARD_INTEGRATION=1", isIntermittent: false) {
            try #require(isEnabled)
        } when: {
            !isEnabled
        }
        guard isEnabled else { return }

        let store = CFPreferencesStore(domain: Self.stateDomain)
        try clean(store)
        defer { try? clean(store) }

        let state = DockState(
            apps: [
                .app(path: "/Applications/Slack.app", label: "Slack", bundleID: "com.tinyspeck.slackmacgap"),
                DockTile(kind: .spacer),
                DockTile(kind: .smallSpacer),
                DockTile(kind: .flexSpacer),
            ],
            others: [
                DockTile(
                    kind: .folder,
                    path: "/Users/someone/Downloads",
                    label: "Downloads",
                    folder: FolderOptions(showAs: .fan, displayAs: .folder, arrangement: .dateAdded)
                ),
                DockTile(kind: .url, url: "https://github.com", label: "GitHub"),
            ],
            settings: DockSettings(
                orientation: .bottom,
                tileSize: 48,
                magnification: false,
                autohide: true,
                minimizeEffect: .genie
            )
        )

        let controller = DockController(store: store, restarter: NoopDockRestarter(), backups: nil)
        try controller.apply(state, options: .init(createBackup: false, restartDock: false))

        let readBack = controller.read()

        // bundle-identifier is deliberately never written: the real Dock backfills it from
        // the path. A scratch domain has no Dock, so it comes back nil — that is the design
        // working, not a round-trip failure.
        #expect(readBack.apps.map(\.path) == state.apps.map(\.path))
        #expect(readBack.apps.map(\.kind) == state.apps.map(\.kind))
        #expect(readBack.apps.map(\.label) == state.apps.map(\.label))
        #expect(readBack.apps.allSatisfy { $0.bundleID == nil })
        #expect(readBack.others == state.others)
        #expect(readBack.settings == state.settings)
    }

    @Test func booleansSurviveTheCFPropertyListBridge() throws {
        guard isEnabled else { return }

        let store = CFPreferencesStore(domain: Self.settingsDomain)
        try clean(store)
        defer { try? clean(store) }

        try store.setValues(["autohide": .bool(true), "tilesize": .double(64), "orientation": .string("left")])
        #expect(store.value(forKey: "autohide") == .bool(true))
        #expect(store.value(forKey: "tilesize")?.doubleValue == 64)
        #expect(store.value(forKey: "orientation")?.stringValue == "left")
    }
}
