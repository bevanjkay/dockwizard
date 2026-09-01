import ArgumentParser
import DockCore
import Foundation
import PresetCore

struct Apply: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Replace the Dock with a preset.",
        discussion: """
        Apply is replace-only: the preset is the complete truth for the tiles it contains. \
        Settings are partial — only the keys the preset carries are written.

        Exit codes: 0 success, 2 applied with items skipped, 1 error.
        """
    )

    @OptionGroup var libraryOptions: LibraryOptions
    @OptionGroup var applyOptions: ApplyOptions

    @Argument(help: "Preset name from the library, or a path to a preset file.")
    var preset: String

    func run() throws {
        let loaded = try libraryOptions.library.load(preset)
        let resolution = PresetResolver().resolve(loaded.preset)
        try Session.apply(
            state: resolution.state,
            missing: resolution.missing,
            options: applyOptions,
            warnings: loaded.warnings
        )
    }
}
