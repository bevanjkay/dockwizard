import DockCore
import Foundation
import Testing

struct DockTileCodecTests {
    /// Two spikes against macOS 26.6 showed the Dock regenerates `book`, `GUID` and
    /// `bundle-identifier` itself. Writing `book` is what would make presets non-portable,
    /// so this test pins the minimal payload.
    @Test func encodesOnlyTheKeysTheDockNeeds() throws {
        let tile = DockTile.app(path: "/Applications/Slack.app", label: "Slack", bundleID: "com.tinyspeck.slackmacgap")
        let encoded = DockTileCodec.encode(tile)
        let data = try #require(encoded["tile-data"]?.dictionaryValue)

        #expect(encoded["tile-type"]?.stringValue == "file-tile")
        #expect(Set(data.keys) == ["file-data", "file-label"])
        #expect(data["file-data"]?["_CFURLString"]?.stringValue == "file:///Applications/Slack.app")
        #expect(data["file-data"]?["_CFURLStringType"]?.intValue == 15)
        #expect(data["bundle-identifier"] == nil)
        #expect(data["book"] == nil)
    }

    @Test func decodesAnApplicationTileFromRealDockShape() throws {
        let value = PlistValue.dictionary([
            "GUID": .int(1_159_904_550),
            "tile-type": .string("file-tile"),
            "tile-data": .dictionary([
                "book": .data(Data([0, 1, 2])),
                "bundle-identifier": .string("com.apple.Chess"),
                "file-label": .string("Chess"),
                "file-data": .dictionary([
                    "_CFURLString": .string("file:///System/Applications/Chess.app/"),
                    "_CFURLStringType": .int(15),
                ]),
            ]),
        ])
        let tile = try #require(DockTileCodec.decode(value))
        #expect(tile.kind == .app)
        #expect(tile.path == "/System/Applications/Chess.app")
        #expect(tile.label == "Chess")
        #expect(tile.bundleID == "com.apple.Chess")
    }

    @Test func decodesPathsWithPercentEscapes() throws {
        let value = PlistValue.dictionary([
            "tile-type": .string("file-tile"),
            "tile-data": .dictionary([
                "file-label": .string("Brave Browser"),
                "file-data": .dictionary([
                    "_CFURLString": .string("file:///Applications/Brave%20Browser.app/"),
                ]),
            ]),
        ])
        let tile = try #require(DockTileCodec.decode(value))
        #expect(tile.path == "/Applications/Brave Browser.app")
    }

    @Test func roundTripsEveryTileKind() throws {
        let tiles: [DockTile] = [
            .app(path: "/Applications/Slack.app", label: "Slack"),
            DockTile(kind: .file, path: "/Users/someone/notes.md", label: "notes.md"),
            DockTile(
                kind: .folder,
                path: "/Users/someone/Downloads",
                label: "Downloads",
                folder: FolderOptions(showAs: .fan, displayAs: .folder, arrangement: .dateAdded)
            ),
            DockTile(kind: .url, url: "https://github.com", label: "GitHub"),
            DockTile(kind: .spacer),
            DockTile(kind: .smallSpacer),
            DockTile(kind: .flexSpacer),
        ]
        for tile in tiles {
            let decoded = try #require(DockTileCodec.decode(DockTileCodec.encode(tile)))
            #expect(decoded.kind == tile.kind, "kind survived for \(tile.kind)")
            #expect(decoded.path == tile.path)
            #expect(decoded.url == tile.url)
            if !tile.kind.isSpacer {
                #expect(decoded.label == tile.label)
            }
            #expect(decoded.folder == tile.folder)
        }
    }

    @Test func folderOptionsUseNamedEnumsNotRawIntegers() throws {
        let tile = DockTile(
            kind: .folder,
            path: "/Users/someone/Downloads",
            label: "Downloads",
            folder: FolderOptions(showAs: .grid, displayAs: .stack, arrangement: .kind, itemSize: nil)
        )
        let data = try #require(DockTileCodec.encode(tile)["tile-data"]?.dictionaryValue)
        #expect(data["showas"]?.intValue == 2)
        #expect(data["displayas"]?.intValue == 0)
        #expect(data["arrangement"]?.intValue == 5)
        #expect(data["preferreditemsize"]?.intValue == -1)
    }

    @Test func ignoresUnknownTileTypes() {
        let value = PlistValue.dictionary(["tile-type": .string("something-new-tile")])
        #expect(DockTileCodec.decode(value) == nil)
    }
}
