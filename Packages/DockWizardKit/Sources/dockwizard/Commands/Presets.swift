import ArgumentParser
import DockCore
import Foundation
import PresetCore

struct Presets: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List the presets in the library."
    )

    @OptionGroup var libraryOptions: LibraryOptions

    @Flag(name: .long, help: "Emit machine-readable JSON.")
    var json = false

    func run() throws {
        let library = libraryOptions.library
        let entries = try library.entries()

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            let payload = entries.map { Item(name: $0.name, path: $0.url.path) }
            try Output.note(json: encoder.encode(payload))
            return
        }

        guard !entries.isEmpty else {
            Output.note("No presets in \(library.directory.path)")
            return
        }
        for entry in entries {
            Output.note("\(entry.name)  (\(entry.url.path))")
        }
    }

    private struct Item: Encodable {
        var name: String
        var path: String
    }
}
