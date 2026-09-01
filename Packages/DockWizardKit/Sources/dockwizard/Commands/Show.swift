import ArgumentParser
import DockCore
import Foundation
import PresetCore

struct Show: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Print a preset, or list the presets in the library."
    )

    @OptionGroup var libraryOptions: LibraryOptions

    @Argument(help: "Preset name or path. Omit to list every preset in the library.")
    var preset: String?

    func run() throws {
        guard let preset else {
            let entries = try libraryOptions.library.entries()
            guard !entries.isEmpty else {
                Output.note("No presets in \(libraryOptions.library.directory.path)")
                return
            }
            for entry in entries {
                Output.note("\(entry.name)  (\(entry.url.path))")
            }
            return
        }
        let loaded = try libraryOptions.library.load(preset)
        for warning in loaded.warnings { Output.warning(warning) }
        let data = try PresetDocument.encode(loaded.preset)
        Output.note(String(decoding: data, as: UTF8.self))
    }
}
