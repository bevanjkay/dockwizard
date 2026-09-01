import DockCore
import PresetCore
import Testing

struct PathTokenizerTests {
    private let home = "/Users/alice"

    @Test func tokenizesPathsInsideHome() {
        #expect(PathTokenizer.tokenize("/Users/alice/Downloads", home: home) == "~/Downloads")
        #expect(PathTokenizer.tokenize("/Users/alice", home: home) == "~")
    }

    @Test func leavesPathsOutsideHomeAlone() {
        #expect(PathTokenizer.tokenize("/Applications/Slack.app", home: home) == "/Applications/Slack.app")
        #expect(PathTokenizer.tokenize("/Users/alicia/Downloads", home: home) == "/Users/alicia/Downloads")
    }

    @Test func expandsBackToADifferentHome() {
        #expect(PathTokenizer.expand("~/Downloads", home: "/Users/bob") == "/Users/bob/Downloads")
        #expect(PathTokenizer.expand("~", home: "/Users/bob") == "/Users/bob")
        #expect(PathTokenizer.expand("/Applications/Slack.app", home: "/Users/bob") == "/Applications/Slack.app")
    }

    @Test func portsAFolderTileBetweenMachines() {
        let tile = DockTile(kind: .folder, path: "/Users/alice/Downloads", label: "Downloads")
        let ported = PathTokenizer.expand(PathTokenizer.tokenize(tile, home: home), home: "/Users/bob")
        #expect(ported.path == "/Users/bob/Downloads")
    }

    @Test func handlesATrailingSlashOnHome() {
        #expect(PathTokenizer.tokenize("/Users/alice/Downloads", home: "/Users/alice/") == "~/Downloads")
    }
}
