import Foundation

/// Reads and writes preset JSON, enforcing the schema version and collecting warnings.
///
/// Unknown keys are tolerated — a preset written by a newer build of DockWizard should still
/// mostly apply — but they are reported so nothing is dropped silently. A `schemaVersion`
/// higher than this build understands is a hard error.
public enum PresetDocument {
    public struct LoadResult: Sendable {
        public var preset: Preset
        public var warnings: [String]

        public init(preset: Preset, warnings: [String] = []) {
            self.preset = preset
            self.warnings = warnings
        }
    }

    public static func load(from url: URL) throws -> LoadResult {
        do {
            return try load(data: Data(contentsOf: url), source: url.lastPathComponent)
        } catch let error as PresetError {
            throw error
        } catch {
            throw PresetError.unreadable(url, underlying: error.localizedDescription)
        }
    }

    public static func load(data: Data, source: String = "preset") throws -> LoadResult {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw PresetError.invalidJSON(source, underlying: error.localizedDescription)
        }
        guard let root = object as? [String: Any] else {
            throw PresetError.invalidJSON(source, underlying: "The document is not a JSON object.")
        }

        guard let version = root["schemaVersion"] as? Int else {
            throw PresetError.missingSchemaVersion(source)
        }
        guard version <= Preset.currentSchemaVersion else {
            throw PresetError.unsupportedSchemaVersion(source, found: version, supported: Preset.currentSchemaVersion)
        }

        var warnings = unknownKeyWarnings(in: root, source: source)

        let preset: Preset
        do {
            preset = try JSONDecoder().decode(Preset.self, from: data)
        } catch {
            throw PresetError.decodingFailed(source, underlying: describe(error))
        }

        if preset.apps.isEmpty, preset.others.isEmpty {
            warnings.append("\(source) contains no tiles; applying it would empty the Dock.")
        }
        return LoadResult(preset: preset, warnings: warnings)
    }

    public static func encode(_ preset: Preset) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(preset)
    }

    public static func write(_ preset: Preset, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        var data = try encode(preset)
        data.append(0x0A)
        try data.write(to: url, options: .atomic)
    }

    private static let knownTileKeys: Set<String> = ["type", "path", "url", "label", "bundleId", "folder"]
    private static let knownFolderKeys: Set<String> = ["showAs", "displayAs", "arrangement", "itemSize"]

    private static func unknownKeyWarnings(in root: [String: Any], source: String) -> [String] {
        var warnings: [String] = []
        for key in root.keys.sorted() where !Preset.knownKeys.contains(key) {
            warnings.append("\(source): ignoring unknown key '\(key)'.")
        }
        for section in ["apps", "others"] {
            guard let tiles = root[section] as? [[String: Any]] else { continue }
            for (index, tile) in tiles.enumerated() {
                for key in tile.keys.sorted() where !knownTileKeys.contains(key) {
                    warnings.append("\(source): ignoring unknown key '\(key)' on \(section)[\(index)].")
                }
                guard let folder = tile["folder"] as? [String: Any] else { continue }
                for key in folder.keys.sorted() where !knownFolderKeys.contains(key) {
                    warnings.append("\(source): ignoring unknown key 'folder.\(key)' on \(section)[\(index)].")
                }
            }
        }
        return warnings
    }

    private static func describe(_ error: Error) -> String {
        guard let decoding = error as? DecodingError else { return error.localizedDescription }
        switch decoding {
        case let .keyNotFound(key, context):
            return "missing key '\(key.stringValue)' at \(path(context))"
        case let .typeMismatch(_, context), let .valueNotFound(_, context):
            return "\(context.debugDescription) at \(path(context))"
        case let .dataCorrupted(context):
            return context.debugDescription
        @unknown default:
            return error.localizedDescription
        }
    }

    private static func path(_ context: DecodingError.Context) -> String {
        let components = context.codingPath.map(\.stringValue)
        return components.isEmpty ? "the document root" : components.joined(separator: ".")
    }
}
