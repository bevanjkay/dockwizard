import DockCore
import Testing

struct DockDiffTests {
    private let slack = DockTile.app(path: "/Applications/Slack.app", label: "Slack")
    private let trello = DockTile.app(path: "/Applications/Trello.app", label: "Trello")
    private let bear = DockTile.app(path: "/Applications/Bear.app", label: "Bear")

    @Test func reportsNoChangesForIdenticalStates() {
        let state = DockState(apps: [slack, trello])
        #expect(DockDiff.between(current: state, target: state).isEmpty)
    }

    @Test func reportsAdditionsAndRemovals() throws {
        let diff = DockDiff.between(
            current: DockState(apps: [slack, trello]),
            target: DockState(apps: [slack, bear])
        )
        let apps = try #require(diff.sections.first { $0.section == .apps })
        #expect(apps.added.map(\.displayName) == ["Bear"])
        #expect(apps.removed.map(\.displayName) == ["Trello"])
    }

    @Test func detectsReorderingOfOtherwiseIdenticalTiles() throws {
        let diff = DockDiff.between(
            current: DockState(apps: [slack, trello]),
            target: DockState(apps: [trello, slack])
        )
        let apps = try #require(diff.sections.first { $0.section == .apps })
        #expect(apps.added.isEmpty)
        #expect(apps.removed.isEmpty)
        #expect(apps.reordered)
    }

    @Test func relabellingATileIsNotAnAddAndRemove() throws {
        var renamed = slack
        renamed.label = "Slack (work)"
        let diff = DockDiff.between(
            current: DockState(apps: [slack]),
            target: DockState(apps: [renamed])
        )
        let apps = try #require(diff.sections.first { $0.section == .apps })
        #expect(apps.isEmpty)
    }

    @Test func listsOnlySettingsThatActuallyChange() {
        let diff = DockDiff.between(
            current: DockState(settings: DockSettings(tileSize: 48, autohide: false)),
            target: DockState(settings: DockSettings(tileSize: 64, autohide: false))
        )
        #expect(diff.settings.map(\.key) == ["tilesize"])
        #expect(diff.settings.first?.before == "48")
        #expect(diff.settings.first?.after == "64")
    }
}
