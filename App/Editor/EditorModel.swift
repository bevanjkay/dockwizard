import AppKit
import DockCore
import Foundation
import PresetCore
import SwiftUI

/// The staged editing model.
///
/// Every write to the Dock costs a `killall Dock`, so edits accumulate here and are committed
/// by an explicit Apply. That also means a preset can be edited and saved without ever
/// touching the running Dock.
@MainActor
@Observable
final class EditorModel {
    private(set) var baseline: DockState
    private(set) var settings: DockSettings

    var apps: [TileItem]
    var others: [TileItem]
    var selection: Set<TileItem.ID> = []

    /// Tiles from the last loaded preset that could not be placed on this machine.
    private(set) var missing: [MissingTile] = []
    private(set) var warnings: [String] = []
    private(set) var loadedPresetName: String?

    var presets: [PresetLibrary.Entry] = []
    var status: Status?
    var sheet: Sheet?

    private let controller: DockController

    init(controller: DockController = DockController()) {
        self.controller = controller
        let state = controller.read()
        baseline = state
        settings = state.settings
        apps = [TileItem](state.apps)
        others = [TileItem](state.others)
        reloadPresets()
    }

    // MARK: - State

    var stagedState: DockState {
        DockState(apps: apps.tiles, others: others.tiles, settings: settings)
    }

    var hasStagedChanges: Bool {
        stagedState != baseline
    }

    var diff: DockDiff {
        DockDiff.between(current: baseline, target: stagedState)
    }

    subscript(section: DockState.Section) -> [TileItem] {
        get {
            switch section {
            case .apps: apps
            case .others: others
            }
        }
        set {
            switch section {
            case .apps: apps = newValue
            case .others: others = newValue
            }
        }
    }

    func section(containing id: TileItem.ID) -> DockState.Section? {
        DockState.Section.allCases.first { self[$0].contains { $0.id == id } }
    }

    /// The selection, grouped by the section each tile lives in.
    var selectedBySection: [DockState.Section: [Int]] {
        var result: [DockState.Section: [Int]] = [:]
        for section in DockState.Section.allCases {
            let indices = self[section].indices.filter { selection.contains(self[section][$0].id) }
            if !indices.isEmpty {
                result[section] = indices
            }
        }
        return result
    }

    // MARK: - Reading and reverting

    func reloadFromDock() {
        let state = controller.read()
        baseline = state
        settings = state.settings
        apps = [TileItem](state.apps)
        others = [TileItem](state.others)
        selection = []
        missing = []
        warnings = []
        loadedPresetName = nil
        status = .info("Reloaded from the Dock.")
    }

    func revert() {
        settings = baseline.settings
        apps = [TileItem](baseline.apps)
        others = [TileItem](baseline.others)
        selection = []
        missing = []
        warnings = []
        loadedPresetName = nil
    }

    // MARK: - Editing

    func removeSelection() {
        guard !selection.isEmpty else { return }
        for section in DockState.Section.allCases {
            self[section].removeAll { selection.contains($0.id) }
        }
        selection = []
    }

    func move(_ section: DockState.Section, from offsets: IndexSet, to destination: Int) {
        self[section].move(fromOffsets: offsets, toOffset: destination)
    }

    func insert(_ tile: DockTile, into section: DockState.Section, at index: Int? = nil) {
        let item = TileItem(tile)
        let target = index ?? self[section].count
        self[section].insert(item, at: min(max(target, 0), self[section].count))
        selection = [item.id]
    }

    /// Puts a spacer on either side of the selection, which is the usual reason to select a
    /// run of tiles in the first place.
    func wrapSelectionInSpacers() {
        for (section, indices) in selectedBySection {
            guard let first = indices.min(), let last = indices.max() else { continue }
            self[section].insert(TileItem(DockTile(kind: .spacer)), at: last + 1)
            self[section].insert(TileItem(DockTile(kind: .spacer)), at: first)
        }
    }

    func moveSelection(toPosition position: Int) {
        for (section, indices) in selectedBySection {
            let moving = indices.map { self[section][$0] }
            self[section].removeAll { id in moving.contains { $0.id == id.id } }
            let target = min(max(position - 1, 0), self[section].count)
            self[section].insert(contentsOf: moving, at: target)
        }
    }

    var selectedTiles: [DockTile] {
        DockState.Section.allCases.flatMap { section in
            self[section].filter { selection.contains($0.id) }.tiles
        }
    }

    // MARK: - Presets

    var library: PresetLibrary {
        PresetLibrary.default(override: UserDefaults.standard.string(forKey: PreferenceKey.presetsDirectoryOverride))
    }

    func reloadPresets() {
        presets = (try? library.entries()) ?? []
    }

    func loadPreset(_ entry: PresetLibrary.Entry) {
        do {
            let loaded = try PresetDocument.load(from: entry.url)
            let resolution = PresetResolver().resolve(loaded.preset)
            apps = [TileItem](resolution.state.apps)
            others = [TileItem](resolution.state.others)
            if let presetSettings = loaded.preset.settings {
                settings = presetSettings
            }
            missing = resolution.missing
            warnings = loaded.warnings
            loadedPresetName = entry.name
            selection = []
            status = .info("Loaded \(entry.name). Nothing has been applied yet.")
        } catch {
            status = .failure(error.localizedDescription)
        }
    }

    func savePreset(named name: String, tiles: [DockTile]? = nil, includeSettings: Bool = true) {
        let state: DockState = if let tiles {
            DockState(
                apps: tiles.filter { $0.kind == .app || $0.kind.isSpacer },
                others: tiles.filter { !($0.kind == .app || $0.kind.isSpacer) },
                settings: settings
            )
        } else {
            stagedState
        }
        do {
            let preset = Preset.capturing(state, name: name, includeSettings: includeSettings)
            let url = try library.save(preset, as: name)
            reloadPresets()
            status = .info("Saved \(url.lastPathComponent).")
        } catch {
            status = .failure(error.localizedDescription)
        }
    }

    func deletePreset(_ entry: PresetLibrary.Entry) {
        do {
            try library.delete(entry)
            reloadPresets()
            status = .info("Deleted \(entry.name).")
        } catch {
            status = .failure(error.localizedDescription)
        }
    }

    // MARK: - Applying

    /// Shows the missing-apps confirmation unless the user has turned it off, then applies.
    func requestApply() {
        let skipPrompt = UserDefaults.standard.bool(forKey: PreferenceKey.skipMissingAppsPrompt)
        if !missing.isEmpty, !skipPrompt {
            sheet = .confirmMissing
        } else {
            apply()
        }
    }

    func apply() {
        sheet = nil
        do {
            let result = try controller.apply(stagedState)
            baseline = stagedState
            let backup = result.backup.map { " Backed up to \($0.name)." } ?? ""
            if missing.isEmpty {
                status = .info("Applied to the Dock.\(backup)")
            } else {
                // Suppressing the dialog must never suppress the fact.
                status = .warning("Applied, skipping \(missing.count) missing item(s).\(backup)")
            }
        } catch {
            status = .failure(error.localizedDescription)
        }
    }

    func restoreMostRecentBackup() {
        do {
            guard let backup = try DockBackupStore.defaultStore().mostRecent() else {
                status = .warning("There are no snapshots to restore.")
                return
            }
            try controller.restore(backup)
            reloadFromDock()
            status = .info("Restored \(backup.name).")
        } catch {
            status = .failure(error.localizedDescription)
        }
    }

    // MARK: - Presentation

    enum Status: Equatable {
        case info(String)
        case warning(String)
        case failure(String)

        var message: String {
            switch self {
            case let .info(text), let .warning(text), let .failure(text): text
            }
        }
    }

    enum Sheet: Identifiable {
        case confirmMissing
        case addApplication
        case savePreset(tiles: [DockTile]?)
        case moveToPosition

        var id: String {
            switch self {
            case .confirmMissing: "confirmMissing"
            case .addApplication: "addApplication"
            case .savePreset: "savePreset"
            case .moveToPosition: "moveToPosition"
            }
        }
    }
}
