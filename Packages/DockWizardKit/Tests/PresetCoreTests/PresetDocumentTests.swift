import DockCore
import Foundation
import PresetCore
import Testing

struct PresetDocumentTests {
    private func data(_ json: String) -> Data {
        Data(json.utf8)
    }

    private func text(_ data: Data) -> String {
        String(bytes: data, encoding: .utf8) ?? ""
    }

    @Test func readsAMinimalPreset() throws {
        let result = try PresetDocument.load(data: data("""
        {
          "schemaVersion": 1,
          "name": "Work",
          "apps": [{ "type": "app", "path": "/Applications/Slack.app", "label": "Slack" }],
          "others": []
        }
        """))
        #expect(result.preset.name == "Work")
        #expect(result.preset.apps.first?.kind == .app)
        #expect(result.warnings.isEmpty)
    }

    @Test func rejectsADocumentWithNoSchemaVersion() {
        #expect(throws: PresetError.self) {
            try PresetDocument.load(data: data(#"{ "apps": [] }"#))
        }
    }

    @Test func rejectsANewerSchemaOutright() throws {
        let error = #expect(throws: PresetError.self) {
            try PresetDocument.load(data: data(#"{ "schemaVersion": 99, "apps": [], "others": [] }"#))
        }
        #expect(error == .unsupportedSchemaVersion("preset", found: 99, supported: 1))
    }

    @Test func warnsAboutUnknownKeysInsteadOfFailing() throws {
        let result = try PresetDocument.load(data: data("""
        {
          "schemaVersion": 1,
          "mysteryKey": true,
          "apps": [{ "type": "spacer", "futureOption": 3 }],
          "others": []
        }
        """))
        #expect(result.preset.apps.count == 1)
        #expect(result.warnings.count == 2)
        #expect(result.warnings.contains { $0.contains("mysteryKey") })
        #expect(result.warnings.contains { $0.contains("futureOption") })
    }

    @Test func warnsWhenAPresetWouldEmptyTheDock() throws {
        let result = try PresetDocument.load(data: data(#"{ "schemaVersion": 1, "apps": [], "others": [] }"#))
        #expect(result.warnings.contains { $0.contains("empty the Dock") })
    }

    @Test func reportsBadJSONWithoutCrashing() {
        #expect(throws: PresetError.self) {
            try PresetDocument.load(data: data("{ not json"))
        }
    }

    @Test func roundTripsThroughEncodeAndLoad() throws {
        let state = DockState(
            apps: [.app(path: "/Applications/Slack.app", label: "Slack", bundleID: "com.tinyspeck.slackmacgap")],
            others: [DockTile(
                kind: .folder,
                path: "/Users/alice/Downloads",
                label: "Downloads",
                folder: FolderOptions(showAs: .fan, displayAs: .folder, arrangement: .name)
            )],
            settings: DockSettings(orientation: .bottom, tileSize: 48)
        )
        let preset = Preset.capturing(state, name: "Work", home: "/Users/alice")
        let reloaded = try PresetDocument.load(data: PresetDocument.encode(preset)).preset
        #expect(reloaded == preset)
        #expect(reloaded.others.first?.path == "~/Downloads")
    }

    @Test func omitsSettingsWhenAsked() throws {
        let preset = Preset.capturing(
            DockState(settings: DockSettings(tileSize: 48)),
            includeSettings: false
        )
        #expect(preset.settings == nil)
        let json = try text(PresetDocument.encode(preset))
        #expect(!json.contains("settings"))
    }

    @Test func usesTheDocumentedJSONKeyNames() throws {
        let preset = Preset(
            name: "Work",
            summary: "Dev and comms",
            apps: [.app(path: "/Applications/Slack.app", label: "Slack", bundleID: "com.tinyspeck.slackmacgap")]
        )
        let json = try text(PresetDocument.encode(preset))
        #expect(json.contains("\"description\""))
        #expect(json.contains("\"bundleId\""))
        #expect(json.contains("\"type\" : \"app\""))
    }
}
