import Foundation

public enum PresetError: Error, Equatable, LocalizedError {
    case unreadable(URL, underlying: String)
    case invalidJSON(String, underlying: String)
    case missingSchemaVersion(String)
    case unsupportedSchemaVersion(String, found: Int, supported: Int)
    case decodingFailed(String, underlying: String)
    case presetNotFound(String)
    case ambiguousName(String)

    public var errorDescription: String? {
        switch self {
        case let .unreadable(url, underlying):
            "Could not read \(url.path): \(underlying)"
        case let .invalidJSON(source, underlying):
            "\(source) is not valid JSON: \(underlying)"
        case let .missingSchemaVersion(source):
            "\(source) has no 'schemaVersion'. DockWizard presets must declare one."
        case let .unsupportedSchemaVersion(source, found, supported):
            """
            \(source) uses schema version \(found) but this build understands up to \(supported). \
            Update DockWizard to apply it.
            """
        case let .decodingFailed(source, underlying):
            "Could not read \(source): \(underlying)"
        case let .presetNotFound(name):
            "No preset named '\(name)'. Run 'dockwizard list' to see what is available."
        case let .ambiguousName(name):
            "More than one preset matches '\(name)'."
        }
    }
}
