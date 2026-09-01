import ArgumentParser
import DockCore
import Foundation
import PresetCore

struct Remove: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Remove a tile from the Dock.",
        discussion: """
        The target is either a 1-indexed position (see 'dockwizard list') or a tile label. \
        A numeric target needs --section when the tile is not in the apps section.
        """
    )

    @OptionGroup var applyOptions: ApplyOptions

    @Argument(help: "1-indexed position, or a tile label.")
    var target: String

    @Option(name: .long, help: "Which section the position refers to. Defaults to apps.")
    var section: DockState.Section?

    func run() throws {
        let controller = Session.controller(createBackup: applyOptions.backup)
        var state = controller.read()

        if let position = Int(target) {
            let section = section ?? .apps
            var tiles = state[section]
            guard tiles.indices.contains(position - 1) else {
                throw ValidationError("\(section.rawValue) has no position \(position).")
            }
            let removed = tiles.remove(at: position - 1)
            state[section] = tiles
            Output.note("Removing \(removed.displayName)")
        } else {
            var removedAny = false
            for candidate in DockState.Section.allCases where section == nil || section == candidate {
                var tiles = state[candidate]
                let matches = tiles.enumerated().filter {
                    $0.element.displayName.caseInsensitiveCompare(target) == .orderedSame
                }
                guard !matches.isEmpty else { continue }
                for match in matches.reversed() {
                    Output.note("Removing \(match.element.displayName) from \(candidate.rawValue)")
                    tiles.remove(at: match.offset)
                }
                state[candidate] = tiles
                removedAny = true
            }
            guard removedAny else {
                throw ValidationError("No tile labelled '\(target)' is in the Dock.")
            }
        }

        try Session.apply(state: state, missing: [], options: applyOptions)
    }
}

struct Move: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Move a tile to another position.",
        discussion: "Both positions are 1-indexed and count spacers."
    )

    @OptionGroup var applyOptions: ApplyOptions

    @Argument(help: "Current 1-indexed position.")
    var from: Int

    @Argument(help: "Target 1-indexed position.")
    var to: Int

    @Option(name: .long, help: "Which section to move within. Defaults to apps.")
    var section: DockState.Section?

    func validate() throws {
        guard from >= 1, to >= 1 else {
            throw ValidationError("Positions are 1-indexed and must be 1 or greater.")
        }
    }

    func run() throws {
        let section = section ?? .apps
        let controller = Session.controller(createBackup: applyOptions.backup)
        var state = controller.read()
        var tiles = state[section]

        guard tiles.indices.contains(from - 1) else {
            throw ValidationError("\(section.rawValue) has no position \(from).")
        }
        let tile = tiles.remove(at: from - 1)
        tiles.insert(tile, at: min(to - 1, tiles.count))
        state[section] = tiles

        Output.note("Moving \(tile.displayName) from \(from) to \(to)")
        try Session.apply(state: state, missing: [], options: applyOptions)
    }
}
