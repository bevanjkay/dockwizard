import ArgumentParser
import DockCore
import Foundation
import PresetCore

struct Add: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Add a single tile to the Dock.",
        discussion: """
        The target is an application path, a folder, a URL, a bundle identifier, or one of \
        the keywords 'spacer', 'small-spacer' and 'flex-spacer'.

        Positions are 1-indexed and count spacers.
        """
    )

    @OptionGroup var applyOptions: ApplyOptions

    @Argument(help: "Path, bundle identifier, URL, or a spacer keyword.")
    var target: String

    @Flag(name: .long, help: "Insert at the beginning of the section.")
    var start = false

    @Flag(name: .long, help: "Append to the end of the section. This is the default.")
    var end = false

    @Option(name: .long, help: "Insert so the tile ends up at this 1-indexed position.")
    var position: Int?

    @Option(name: .long, help: "Which section to add to: apps or others.")
    var section: DockState.Section?

    func validate() throws {
        let choices = [start, end, position != nil].filter { $0 }.count
        guard choices <= 1 else {
            throw ValidationError("Use only one of --start, --end and --position.")
        }
        if let position, position < 1 {
            throw ValidationError("Positions are 1-indexed; --position must be 1 or greater.")
        }
    }

    func run() throws {
        let tile = try TileFactory.make(from: target)
        let controller = Session.controller(createBackup: applyOptions.backup)
        var state = controller.read()
        let section = section ?? TileFactory.defaultSection(for: tile)

        var tiles = state[section]
        let index: Int
        if start {
            index = 0
        } else if let position {
            index = min(position - 1, tiles.count)
        } else {
            index = tiles.count
        }
        tiles.insert(tile, at: index)
        state[section] = tiles

        try Session.apply(state: state, missing: [], options: applyOptions)
    }
}

enum TileFactory {
    static func make(from target: String) throws -> DockTile {
        switch target.lowercased() {
        case "spacer": return DockTile(kind: .spacer)
        case "small-spacer", "smallspacer": return DockTile(kind: .smallSpacer)
        case "flex-spacer", "flexspacer": return DockTile(kind: .flexSpacer)
        default: break
        }

        if target.hasPrefix("http://") || target.hasPrefix("https://") {
            return DockTile(kind: .url, url: target, label: target)
        }

        let locator = SystemApplicationLocator()
        let expanded = (target as NSString).expandingTildeInPath

        if target.contains("/") || target.hasSuffix(".app") {
            guard locator.fileExists(atPath: expanded) else {
                throw ValidationError("Nothing exists at \(expanded).")
            }
            var isDirectory: ObjCBool = false
            _ = FileManager.default.fileExists(atPath: expanded, isDirectory: &isDirectory)
            let isBundle = expanded.hasSuffix(".app")
            let kind: TileKind = isBundle ? .app : (isDirectory.boolValue ? .folder : .file)
            return DockTile(
                kind: kind,
                path: expanded,
                label: (expanded as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: ""),
                bundleID: isBundle ? locator.bundleIdentifier(atPath: expanded) : nil
            )
        }

        guard let url = locator.url(forBundleIdentifier: target) else {
            throw ValidationError("No installed application with bundle identifier \(target).")
        }
        return DockTile(
            kind: .app,
            path: url.path,
            label: url.deletingPathExtension().lastPathComponent,
            bundleID: target
        )
    }

    static func defaultSection(for tile: DockTile) -> DockState.Section {
        switch tile.kind {
        case .app, .spacer, .smallSpacer, .flexSpacer: .apps
        case .file, .folder, .url: .others
        }
    }
}

extension DockState.Section: ExpressibleByArgument {}
