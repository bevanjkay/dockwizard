import Foundation

/// Translates between `DockTile` and the Dock's plist tile dictionaries.
///
/// The write side is deliberately minimal. Two spikes against macOS 26.6 confirmed that a
/// tile carrying only `tile-type`, `file-data._CFURLString` and `file-label` is accepted, and
/// that the Dock regenerates `GUID`, the `book` bookmark blob, `bundle-identifier`,
/// `file-type` and the modification dates itself on next launch. Writing `book` ourselves is
/// what would make presets non-portable, so we never do.
public enum DockTileCodec {
    // MARK: - Decoding

    public static func decode(_ value: PlistValue) -> DockTile? {
        guard let tileType = value[DockKeys.Tile.tileType]?.stringValue else { return nil }
        let data = value[DockKeys.Tile.tileData]

        let label = data?[DockKeys.Tile.fileLabel]?.stringValue
            ?? data?[DockKeys.Tile.label]?.stringValue

        let filePath = data?[DockKeys.Tile.fileData]
            .flatMap { urlString(in: $0) }
            .flatMap(path(fromFileURL:))

        guard let kind = TileKind.from(dockTileType: tileType, path: filePath) else { return nil }

        if kind.isSpacer {
            return DockTile(kind: kind)
        }

        if kind == .url {
            let address = data?[DockKeys.Tile.url].flatMap { urlString(in: $0) }
            return DockTile(kind: .url, url: address, label: label)
        }

        var tile = DockTile(
            kind: kind,
            path: filePath,
            label: label,
            bundleID: data?[DockKeys.Tile.bundleIdentifier]?.stringValue
        )
        if kind == .folder, let data {
            tile.folder = decodeFolderOptions(data)
        }
        return tile
    }

    public static func decodeSection(_ value: PlistValue?) -> [DockTile] {
        (value?.arrayValue ?? []).compactMap(decode)
    }

    private static func decodeFolderOptions(_ data: PlistValue) -> FolderOptions? {
        var options = FolderOptions()
        if let raw = data[DockKeys.Tile.showAs]?.intValue { options.showAs = .init(plistValue: raw) }
        if let raw = data[DockKeys.Tile.displayAs]?.intValue { options.displayAs = .init(plistValue: raw) }
        if let raw = data[DockKeys.Tile.arrangement]?.intValue { options.arrangement = .init(plistValue: raw) }
        if let raw = data[DockKeys.Tile.preferredItemSize]?.intValue, raw != FolderOptions.automaticItemSize {
            options.itemSize = raw
        }
        return options == FolderOptions() ? nil : options
    }

    private static func urlString(in value: PlistValue) -> String? {
        if let nested = value[DockKeys.Tile.urlString]?.stringValue { return nested }
        return value.stringValue
    }

    /// Converts a `file://` URL string to a filesystem path, decoding percent escapes.
    public static func path(fromFileURL string: String) -> String? {
        guard let url = URL(string: string), url.isFileURL else { return nil }
        let path = url.path
        guard path.count > 1, path.hasSuffix("/") else { return path }
        return String(path.dropLast())
    }

    // MARK: - Encoding

    public static func encode(_ tile: DockTile) -> PlistValue {
        var data: [String: PlistValue] = [:]

        switch tile.kind {
        case .spacer, .smallSpacer, .flexSpacer:
            data[DockKeys.Tile.fileLabel] = .string("")
        case .url:
            data[DockKeys.Tile.label] = .string(tile.label ?? tile.url ?? "")
            if let address = tile.url {
                data[DockKeys.Tile.url] = .dictionary([
                    DockKeys.Tile.urlString: .string(address),
                    DockKeys.Tile.urlStringType: .int(DockKeys.absoluteURLStringType),
                ])
            }
        case .app, .file, .folder:
            if let path = tile.path {
                let url = URL(fileURLWithPath: path, isDirectory: tile.kind == .folder)
                data[DockKeys.Tile.fileData] = .dictionary([
                    DockKeys.Tile.urlString: .string(url.absoluteString),
                    DockKeys.Tile.urlStringType: .int(DockKeys.absoluteURLStringType),
                ])
            }
            data[DockKeys.Tile.fileLabel] = .string(tile.label ?? tile.displayName)
            if tile.kind == .folder, let folder = tile.folder {
                encodeFolderOptions(folder, into: &data)
            }
        }

        return .dictionary([
            DockKeys.Tile.tileType: .string(tile.kind.dockTileType),
            DockKeys.Tile.tileData: .dictionary(data),
        ])
    }

    public static func encodeSection(_ tiles: [DockTile]) -> PlistValue {
        .array(tiles.map(encode))
    }

    private static func encodeFolderOptions(_ folder: FolderOptions, into data: inout [String: PlistValue]) {
        if let showAs = folder.showAs { data[DockKeys.Tile.showAs] = .int(showAs.plistValue) }
        if let displayAs = folder.displayAs { data[DockKeys.Tile.displayAs] = .int(displayAs.plistValue) }
        if let arrangement = folder.arrangement { data[DockKeys.Tile.arrangement] = .int(arrangement.plistValue) }
        data[DockKeys.Tile.preferredItemSize] = .int(folder.itemSize ?? FolderOptions.automaticItemSize)
    }
}
