import DockCore
import Foundation
import PresetCore
import Testing

struct PresetLibraryTests {
    private func temporaryLibrary() throws -> PresetLibrary {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("dockwizard-library-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return PresetLibrary(directory: url)
    }

    @Test func savesAndListsPresetsByName() throws {
        let library = try temporaryLibrary()
        defer { try? FileManager.default.removeItem(at: library.directory) }

        try library.save(Preset(name: "Work"), as: "Work")
        try library.save(Preset(name: "Home Office"), as: "Home Office")

        #expect(try library.entries().map(\.name) == ["home-office", "work"])
        #expect(try library.load("work").preset.name == "Work")
    }

    @Test func reportsAnUnknownPresetClearly() throws {
        let library = try temporaryLibrary()
        defer { try? FileManager.default.removeItem(at: library.directory) }
        #expect(throws: PresetError.presetNotFound("nope")) {
            try library.url(for: "nope")
        }
    }

    @Test func acceptsAFilesystemPathAsWellAsAName() throws {
        let library = try temporaryLibrary()
        defer { try? FileManager.default.removeItem(at: library.directory) }
        let url = try library.save(Preset(name: "Work"), as: "Work")
        #expect(try library.url(for: url.path) == url)
    }

    @Test func slugsAreFilenameSafe() {
        #expect(PresetLibrary.slug("Work / Home") == "work---home")
        #expect(PresetLibrary.slug("  ") == "preset")
        // Unicode letters are valid in filenames on macOS, so accents survive.
        #expect(PresetLibrary.slug("Café Setup") == "café-setup")
    }

    @Test func missingDirectoryListsAsEmptyRatherThanThrowing() throws {
        let library = PresetLibrary(directory: URL(fileURLWithPath: "/tmp/dockwizard-does-not-exist-\(UUID())"))
        #expect(try library.entries().isEmpty)
    }
}
