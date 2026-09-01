import AppKit
import Foundation

struct InstalledApplication: Identifiable, Hashable, Sendable {
    var url: URL
    var name: String
    var bundleID: String?

    var id: URL {
        url
    }

    var path: String {
        url.path
    }
}

/// Finds applications the way a person would: by looking in the Applications folders.
///
/// A LaunchServices query returns hundreds of helper apps buried inside frameworks and other
/// bundles, so this walks the three real Applications directories instead. It recurses two
/// levels to catch the vendor-subfolder pattern (`/Applications/Adobe Photoshop 2026/…`).
enum InstalledApplications {
    static let searchRoots: [URL] = {
        var roots = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
        ]
        roots.append(URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
            .appendingPathComponent("Applications", isDirectory: true))
        return roots
    }()

    static func scan(maxDepth: Int = 2) async -> [InstalledApplication] {
        await Task.detached(priority: .userInitiated) {
            var found: [URL: InstalledApplication] = [:]
            for root in searchRoots {
                collect(in: root, depth: 0, maxDepth: maxDepth, into: &found)
            }
            return found.values.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }.value
    }

    private static func collect(
        in directory: URL,
        depth: Int,
        maxDepth: Int,
        into found: inout [URL: InstalledApplication]
    ) {
        let manager = FileManager.default
        guard let contents = try? manager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return }

        for url in contents {
            if url.pathExtension == "app" {
                let name = url.deletingPathExtension().lastPathComponent
                found[url] = InstalledApplication(
                    url: url,
                    name: name,
                    bundleID: Bundle(url: url)?.bundleIdentifier
                )
                continue
            }
            guard depth < maxDepth else { continue }
            let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            if isDirectory {
                collect(in: url, depth: depth + 1, maxDepth: maxDepth, into: &found)
            }
        }
    }
}
