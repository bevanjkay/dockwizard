import ArgumentParser
import DockCore
import PresetCore

@main
struct DockWizardCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dockwizard",
        abstract: "Manage the macOS Dock with portable presets.",
        version: PresetGenerator.version,
        subcommands: [
            Export.self,
            Apply.self,
            List.self,
            Show.self,
            Diff.self,
            Add.self,
            Remove.self,
            Move.self,
            Restore.self,
        ],
        defaultSubcommand: List.self
    )
}

/// Exit codes are part of the interface: `2` means "applied, but something was skipped",
/// which a setup script can detect without treating it as a hard failure.
enum CLIExit {
    static let missingApps = ExitCode(2)
}
