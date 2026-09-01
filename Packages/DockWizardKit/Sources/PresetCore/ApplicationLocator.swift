import DockCore
import Foundation
#if canImport(AppKit)
    import AppKit
#endif

/// Finds an installed application by bundle identifier.
///
/// Abstracted so resolution can be unit-tested without depending on what happens to be
/// installed on the machine running the tests.
public protocol ApplicationLocator: Sendable {
    func url(forBundleIdentifier bundleID: String) -> URL?
    func bundleIdentifier(atPath path: String) -> String?
    func fileExists(atPath path: String) -> Bool
}

/// The real locator, backed by LaunchServices.
public struct SystemApplicationLocator: ApplicationLocator {
    public init() {}

    public func url(forBundleIdentifier bundleID: String) -> URL? {
        #if canImport(AppKit)
            return NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
        #else
            return nil
        #endif
    }

    public func bundleIdentifier(atPath path: String) -> String? {
        Bundle(url: URL(fileURLWithPath: path))?.bundleIdentifier
    }

    public func fileExists(atPath path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
}

/// A locator driven by fixtures.
public struct StubApplicationLocator: ApplicationLocator {
    public var installedByBundleID: [String: String]
    public var bundleIDsByPath: [String: String]
    public var existingPaths: Set<String>

    public init(
        installedByBundleID: [String: String] = [:],
        bundleIDsByPath: [String: String] = [:],
        existingPaths: Set<String> = []
    ) {
        self.installedByBundleID = installedByBundleID
        self.bundleIDsByPath = bundleIDsByPath
        self.existingPaths = existingPaths
    }

    public func url(forBundleIdentifier bundleID: String) -> URL? {
        installedByBundleID[bundleID].map { URL(fileURLWithPath: $0) }
    }

    public func bundleIdentifier(atPath path: String) -> String? {
        bundleIDsByPath[path]
    }

    public func fileExists(atPath path: String) -> Bool {
        existingPaths.contains(path) || bundleIDsByPath[path] != nil
    }
}
