import ArgumentParser
import DockCore
import Foundation
import PresetCore

/// Options shared by every command that touches the preset library.
struct LibraryOptions: ParsableArguments {
    @Option(
        name: .long,
        help: "Directory holding presets. Defaults to $DOCKWIZARD_PRESETS_DIR, then Application Support."
    )
    var presetsDir: String?

    var library: PresetLibrary { .default(override: presetsDir) }
}

/// Options shared by every command that writes to the Dock.
struct ApplyOptions: ParsableArguments {
    @Flag(name: .long, help: "Print what would change without touching the Dock.")
    var dryRun = false

    @Flag(name: .long, help: "Change nothing unless every item in the preset resolves.")
    var strict = false

    @Flag(name: .long, help: "Exit 0 even when items were skipped.")
    var quiet = false

    @Flag(name: .long, inversion: .prefixedNo, help: "Snapshot the Dock before applying.")
    var backup = true
}

enum Session {
    static func controller(createBackup: Bool = true) -> DockController {
        DockController(backups: createBackup ? DockBackupStore.defaultStore() : nil)
    }

    /// Writes `state`, honouring `--dry-run`, `--strict` and `--quiet`, and throws the
    /// exit code the caller should surface.
    static func apply(
        state: DockState,
        missing: [MissingTile],
        options: ApplyOptions,
        warnings: [String] = []
    ) throws {
        for warning in warnings {
            Output.warning(warning)
        }

        let controller = controller(createBackup: options.backup)
        let diff = DockDiff.between(current: controller.read(), target: state)

        if options.dryRun {
            Output.report(missing: missing)
            Output.note(Output.render(diff))
            if !missing.isEmpty, !options.quiet { throw CLIExit.missingApps }
            return
        }

        if options.strict, !missing.isEmpty {
            Output.report(missing: missing)
            Output.error("nothing was applied because --strict was set.")
            throw ExitCode.failure
        }

        Output.report(missing: missing)
        let result = try controller.apply(
            state,
            options: DockController.ApplyOptions(createBackup: options.backup, restartDock: true)
        )
        if let backup = result.backup {
            Output.note("Backed up to \(backup.url.path)")
        }
        Output.note(diff.isEmpty ? "Dock already matched; restarted anyway." : Output.render(diff))

        if !missing.isEmpty, !options.quiet {
            throw CLIExit.missingApps
        }
    }
}
