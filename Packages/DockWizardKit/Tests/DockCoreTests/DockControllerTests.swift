import DockCore
import Foundation
import Testing

struct DockControllerTests {
    private func controller(
        _ store: InMemoryPreferencesStore,
        restarter: NoopDockRestarter = NoopDockRestarter()
    ) -> DockController {
        DockController(store: store, restarter: restarter, backups: nil)
    }

    @Test func readsAnEmptyDockWithoutFailing() {
        let state = controller(InMemoryPreferencesStore()).read()
        #expect(state.apps.isEmpty)
        #expect(state.others.isEmpty)
        #expect(state.settings.isEmpty)
    }

    @Test func applyReplacesBothSections() throws {
        let store = InMemoryPreferencesStore(initialValues: [
            "persistent-apps": DockTileCodec.encodeSection([.app(path: "/Applications/Old.app", label: "Old")]),
        ])
        let restarter = NoopDockRestarter()
        let target = DockState(
            apps: [.app(path: "/Applications/New.app", label: "New"), .spacer()],
            others: [DockTile(kind: .folder, path: "/tmp", label: "tmp")]
        )

        try controller(store, restarter: restarter).apply(target, options: .init(createBackup: false))

        let readBack = controller(store).read()
        #expect(readBack.apps.map(\.displayName) == ["New", "— spacer —"])
        #expect(readBack.others.map(\.displayName) == ["tmp"])
        #expect(restarter.restartCount == 1)
    }

    @Test func applyOnlyWritesSettingsThePresetCarries() throws {
        let store = InMemoryPreferencesStore(initialValues: [
            "orientation": .string("bottom"),
            "tilesize": .double(48),
        ])
        let target = DockState(settings: DockSettings(tileSize: 64))

        try controller(store).apply(target, options: .init(createBackup: false))

        #expect(store.value(forKey: "tilesize")?.doubleValue == 64)
        #expect(store.value(forKey: "orientation")?.stringValue == "bottom")
    }

    @Test func settingsRoundTripThroughTheStore() throws {
        let store = InMemoryPreferencesStore()
        let settings = DockSettings(
            orientation: .left,
            tileSize: 36,
            magnification: true,
            autohide: true,
            minimizeEffect: .scale,
            showRecents: false
        )
        try controller(store).apply(DockState(settings: settings), options: .init(createBackup: false))
        #expect(controller(store).read().settings == settings)
    }

    @Test func skipsTheRestartWhenAsked() throws {
        let restarter = NoopDockRestarter()
        try controller(InMemoryPreferencesStore(), restarter: restarter)
            .apply(DockState(), options: .init(createBackup: false, restartDock: false))
        #expect(restarter.restartCount == 0)
    }
}
