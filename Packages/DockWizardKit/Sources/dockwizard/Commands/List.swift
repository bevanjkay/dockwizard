import ArgumentParser
import DockCore
import Foundation
import PresetCore

struct List: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List the tiles currently in the Dock.",
        discussion: """
        Positions are 1-indexed and count spacers, matching the order the Dock stores them. \
        Use these numbers with add --position, remove and move.
        """
    )

    @Flag(name: .long, help: "Emit machine-readable JSON.")
    var json = false

    func run() throws {
        let state = Session.controller(createBackup: false).read()
        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            let payload = Payload(
                apps: state.apps.enumerated().map { Item(index: $0.offset + 1, tile: $0.element) },
                others: state.others.enumerated().map { Item(index: $0.offset + 1, tile: $0.element) },
                settings: state.settings
            )
            Output.note(String(decoding: try encoder.encode(payload), as: UTF8.self))
            return
        }

        for section in DockState.Section.allCases {
            let tiles = state[section]
            Output.note("\(section.rawValue) (\(tiles.count))")
            if tiles.isEmpty {
                Output.note("  (empty)")
            }
            for (offset, tile) in tiles.enumerated() {
                Output.note("  " + Output.describe(tile, index: offset + 1))
            }
        }
    }

    private struct Item: Encodable {
        var index: Int
        var tile: DockTile

        func encode(to encoder: Encoder) throws {
            try tile.encode(to: encoder)
            var container = encoder.container(keyedBy: Key.self)
            try container.encode(index, forKey: .index)
        }

        private enum Key: String, CodingKey { case index }
    }

    private struct Payload: Encodable {
        var apps: [Item]
        var others: [Item]
        var settings: DockSettings
    }
}
