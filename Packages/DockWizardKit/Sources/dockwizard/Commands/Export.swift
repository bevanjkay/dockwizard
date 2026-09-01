import ArgumentParser
import DockCore
import Foundation
import PresetCore

struct Export: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Capture the current Dock as a preset.",
        discussion: "Writes JSON to stdout unless --output or --save is given."
    )

    @OptionGroup var libraryOptions: LibraryOptions

    @Option(name: .shortAndLong, help: "Write the preset to this file.")
    var output: String?

    @Option(name: .long, help: "Save the preset into the preset library under this name.")
    var save: String?

    @Option(name: .long, help: "Name recorded inside the preset.")
    var name: String?

    @Option(name: .long, help: "Description recorded inside the preset.")
    var description: String?

    @Flag(name: .long, help: "Omit Dock appearance settings from the preset.")
    var noSettings = false

    func run() throws {
        let state = Session.controller(createBackup: false).read()
        let preset = Preset.capturing(
            state,
            name: name ?? save,
            summary: description,
            includeSettings: !noSettings
        )

        if let save {
            let url = try libraryOptions.library.save(preset, as: save)
            Output.note("Saved \(url.path)")
            return
        }
        if let output {
            let url = URL(fileURLWithPath: (output as NSString).expandingTildeInPath)
            try PresetDocument.write(preset, to: url)
            Output.note("Wrote \(url.path)")
            return
        }
        try Output.note(json: PresetDocument.encode(preset))
    }
}
