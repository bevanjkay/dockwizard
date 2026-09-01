import Foundation

/// Restarts the Dock so preference changes take effect.
public protocol DockRestarter: Sendable {
    func restart() throws
}

/// Runs `killall Dock`.
public struct ProcessDockRestarter: DockRestarter {
    public init() {}

    public func restart() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["Dock"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        // `killall` exits non-zero when no process matched; a Dock that was not running is
        // not an error, it will pick up the new preferences when it next launches.
    }
}

/// A restarter that records calls instead of touching the running Dock.
public final class NoopDockRestarter: DockRestarter, @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    public var restartCount: Int {
        lock.withLock { count }
    }

    public init() {}

    public func restart() throws {
        lock.withLock { count += 1 }
    }
}
