import ArgumentParser
import DockCore
import Foundation
import PresetCore

struct Show: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Print a preset."
    )

    @OptionGroup var libraryOptions: LibraryOptions

    @Argument(help: "Preset name from the library, or a path to a preset file.")
    var preset: String

    func run() throws {
        let loaded = try libraryOptions.library.load(preset)
        for warning in loaded.warnings {
            Output.warning(warning)
        }
        try Output.note(json: PresetDocument.encode(loaded.preset))
    }
}
