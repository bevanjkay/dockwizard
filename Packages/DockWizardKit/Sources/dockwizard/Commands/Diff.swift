import ArgumentParser
import DockCore
import PresetCore

struct Diff: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Show what applying a preset would change."
    )

    @OptionGroup var libraryOptions: LibraryOptions

    @Argument(help: "Preset name from the library, or a path to a preset file.")
    var preset: String

    func run() throws {
        let loaded = try libraryOptions.library.load(preset)
        for warning in loaded.warnings { Output.warning(warning) }
        let resolution = PresetResolver().resolve(loaded.preset)
        Output.report(missing: resolution.missing)
        let diff = DockDiff.between(
            current: Session.controller(createBackup: false).read(),
            target: resolution.state
        )
        Output.note(Output.render(diff))
        if !resolution.missing.isEmpty { throw CLIExit.missingApps }
    }
}
