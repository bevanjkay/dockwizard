import Foundation

/// Installs the embedded `dockwizard` binary onto the user's PATH.
///
/// `/usr/local/bin` is not writable without authorisation on a stock Mac, so a failure here
/// is expected rather than exceptional: the status carries a command the user can paste.
enum CommandLineTool {
    static let destination = URL(fileURLWithPath: "/usr/local/bin/dockwizard")

    enum Status: Equatable {
        case unknown
        case installed
        case notInstalled
        case unavailable
        case failed(String)

        var description: String {
            switch self {
            case .unknown: "Checking…"
            case .installed: "Installed in /usr/local/bin"
            case .notInstalled: "Not installed"
            case .unavailable: "Not bundled in this build"
            case .failed: "Could not install"
            }
        }
    }

    /// The CLI is copied into the app bundle by `Scripts/package.sh`.
    static var bundledBinary: URL? {
        let candidates = [
            Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/dockwizard"),
            Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/dockwizard"),
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }

    static func status() -> Status {
        guard bundledBinary != nil else { return .unavailable }
        guard let resolved = try? FileManager.default.destinationOfSymbolicLink(atPath: destination.path) else {
            return FileManager.default.fileExists(atPath: destination.path) ? .installed : .notInstalled
        }
        return resolved.contains(Bundle.main.bundleURL.lastPathComponent) ? .installed : .notInstalled
    }

    static func install() -> Status {
        guard let binary = bundledBinary else { return .unavailable }
        let manager = FileManager.default
        do {
            try manager.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if manager.fileExists(atPath: destination.path) {
                try manager.removeItem(at: destination)
            }
            try manager.createSymbolicLink(at: destination, withDestinationURL: binary)
            return .installed
        } catch {
            return .failed(
                "Run this in Terminal instead:\nsudo ln -sf \"\(binary.path)\" \(destination.path)"
            )
        }
    }

    static func uninstall() -> Status {
        do {
            try FileManager.default.removeItem(at: destination)
            return .notInstalled
        } catch {
            return .failed("Run this in Terminal instead:\nsudo rm \(destination.path)")
        }
    }
}
