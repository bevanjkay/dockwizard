import DockCore
import Foundation

/// Turns a preset into a Dock state, resolving every tile against this machine.
///
/// Resolution order for applications, in the order most likely to be correct:
///  1. the recorded path, **verified** to contain the expected bundle identifier;
///  2. LaunchServices, by bundle identifier;
///  3. missing.
///
/// The verification in step 1 is what stops LaunchServices handing back a stale copy from a
/// mounted disk image, `~/Downloads`, or the wrong one of two installs.
public struct PresetResolver: Sendable {
    public let locator: ApplicationLocator
    public let home: String

    public init(locator: ApplicationLocator = SystemApplicationLocator(), home: String = NSHomeDirectory()) {
        self.locator = locator
        self.home = home
    }

    public func resolve(_ preset: Preset) -> Resolution {
        var missing: [MissingTile] = []
        let apps = resolve(preset.apps, section: .apps, missing: &missing)
        let others = resolve(preset.others, section: .others, missing: &missing)
        return Resolution(
            state: DockState(apps: apps, others: others, settings: preset.settings ?? DockSettings()),
            missing: missing
        )
    }

    private func resolve(
        _ tiles: [DockTile],
        section: DockState.Section,
        missing: inout [MissingTile]
    ) -> [DockTile] {
        var resolved: [DockTile] = []
        for (index, tile) in tiles.enumerated() {
            switch resolve(tile) {
            case let .success(value):
                resolved.append(value)
            case let .failure(reason):
                missing.append(MissingTile(tile: tile, section: section, index: index, reason: reason))
            }
        }
        return resolved
    }

    public func resolve(_ tile: DockTile) -> Outcome {
        switch tile.kind {
        case .spacer, .smallSpacer, .flexSpacer, .url:
            return .success(tile)
        case .file, .folder:
            guard let path = tile.path.map({ PathTokenizer.expand($0, home: home) }) else {
                return .failure(.noLocation)
            }
            guard locator.fileExists(atPath: path) else { return .failure(.notFound) }
            var copy = tile
            copy.path = path
            return .success(copy)
        case .app:
            return resolveApplication(tile)
        }
    }

    private func resolveApplication(_ tile: DockTile) -> Outcome {
        let recorded = tile.path.map { PathTokenizer.expand($0, home: home) }
        var mismatch: String?

        if let recorded, locator.fileExists(atPath: recorded) {
            let found = locator.bundleIdentifier(atPath: recorded)
            if tile.bundleID == nil || found == nil || found == tile.bundleID {
                var copy = tile
                copy.path = recorded
                return .success(copy)
            }
            mismatch = found
        }

        if let bundleID = tile.bundleID, let url = locator.url(forBundleIdentifier: bundleID) {
            var copy = tile
            copy.path = url.path
            return .success(copy)
        }

        if let mismatch {
            return .failure(.bundleIdentifierMismatch(found: mismatch))
        }
        return tile.bundleID == nil ? .failure(.noLocation) : .failure(.notInstalled)
    }

    public enum Outcome: Sendable, Equatable {
        case success(DockTile)
        case failure(MissingTile.Reason)
    }

    public struct Resolution: Sendable, Equatable {
        public var state: DockState
        public var missing: [MissingTile]

        public init(state: DockState, missing: [MissingTile] = []) {
            self.state = state
            self.missing = missing
        }

        public var hasMissing: Bool { !missing.isEmpty }
    }
}

/// A tile that could not be placed on this machine.
public struct MissingTile: Sendable, Equatable {
    public var tile: DockTile
    public var section: DockState.Section
    /// Index within the preset's section, for pointing at the offending entry.
    public var index: Int
    public var reason: Reason

    public init(tile: DockTile, section: DockState.Section, index: Int, reason: Reason) {
        self.tile = tile
        self.section = section
        self.index = index
        self.reason = reason
    }

    public enum Reason: Sendable, Equatable {
        case notInstalled
        case notFound
        case noLocation
        case bundleIdentifierMismatch(found: String)

        public var explanation: String {
            switch self {
            case .notInstalled: "not installed"
            case .notFound: "path does not exist"
            case .noLocation: "no path or bundle identifier recorded"
            case let .bundleIdentifierMismatch(found): "different app at that path (\(found))"
            }
        }
    }

    public var description: String {
        "\(tile.displayName) — \(reason.explanation)"
    }
}
