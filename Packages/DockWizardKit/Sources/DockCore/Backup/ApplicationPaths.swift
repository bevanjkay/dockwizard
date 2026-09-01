import Foundation

/// Standard on-disk locations for DockWizard's own data.
public enum ApplicationPaths {
    public static let applicationName = "DockWizard"
    public static let presetsDirectoryEnvironmentKey = "DOCKWIZARD_PRESETS_DIR"

    public static var supportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent(applicationName, isDirectory: true)
    }

    public static var backupsDirectory: URL {
        supportDirectory.appendingPathComponent("backups", isDirectory: true)
    }

    public static var defaultPresetsDirectory: URL {
        supportDirectory.appendingPathComponent("presets", isDirectory: true)
    }

    /// The presets directory, honouring `DOCKWIZARD_PRESETS_DIR` and an optional stored override.
    public static func presetsDirectory(
        override: String? = nil,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> URL {
        if let override, !override.isEmpty {
            return URL(fileURLWithPath: (override as NSString).expandingTildeInPath, isDirectory: true)
        }
        if let fromEnvironment = environment[presetsDirectoryEnvironmentKey], !fromEnvironment.isEmpty {
            return URL(fileURLWithPath: (fromEnvironment as NSString).expandingTildeInPath, isDirectory: true)
        }
        return defaultPresetsDirectory
    }
}
