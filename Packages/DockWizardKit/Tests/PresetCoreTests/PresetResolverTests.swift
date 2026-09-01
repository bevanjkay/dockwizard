import DockCore
import Foundation
import PresetCore
import Testing

struct PresetResolverTests {
    private let slackPath = "/Applications/Slack.app"
    private let slackID = "com.tinyspeck.slackmacgap"

    private func resolver(_ locator: StubApplicationLocator) -> PresetResolver {
        PresetResolver(locator: locator, home: "/Users/bob")
    }

    @Test func usesTheRecordedPathWhenTheBundleIdentifierMatches() {
        let outcome = resolver(StubApplicationLocator(bundleIDsByPath: [slackPath: slackID]))
            .resolve(.app(path: slackPath, label: "Slack", bundleID: slackID))
        #expect(outcome == .success(.app(path: slackPath, label: "Slack", bundleID: slackID)))
    }

    /// A stale copy on a mounted disk image is exactly what the verification step exists to
    /// avoid, so a mismatch must fall through to LaunchServices rather than trusting the path.
    @Test func fallsBackToLaunchServicesWhenTheBundleIdentifierDiffers() {
        let locator = StubApplicationLocator(
            installedByBundleID: [slackID: slackPath],
            bundleIDsByPath: ["/Volumes/Slack/Slack.app": "com.example.impostor", slackPath: slackID]
        )
        let outcome = resolver(locator)
            .resolve(.app(path: "/Volumes/Slack/Slack.app", label: "Slack", bundleID: slackID))
        guard case let .success(tile) = outcome else {
            Issue.record("expected the LaunchServices copy")
            return
        }
        #expect(tile.path == slackPath)
    }

    @Test func findsAnAppThatMovedSinceTheExport() {
        let locator = StubApplicationLocator(installedByBundleID: [slackID: "/Users/bob/Applications/Slack.app"])
        let outcome = resolver(locator).resolve(.app(path: slackPath, label: "Slack", bundleID: slackID))
        guard case let .success(tile) = outcome else {
            Issue.record("expected a LaunchServices hit")
            return
        }
        #expect(tile.path == "/Users/bob/Applications/Slack.app")
    }

    @Test func reportsAnAppThatIsNotInstalled() {
        let outcome = resolver(StubApplicationLocator())
            .resolve(.app(path: slackPath, label: "Slack", bundleID: slackID))
        #expect(outcome == .failure(.notInstalled))
    }

    @Test func reportsAMismatchWhenLaunchServicesAlsoComesUpEmpty() {
        let locator = StubApplicationLocator(bundleIDsByPath: [slackPath: "com.example.impostor"])
        let outcome = resolver(locator).resolve(.app(path: slackPath, label: "Slack", bundleID: slackID))
        #expect(outcome == .failure(.bundleIdentifierMismatch(found: "com.example.impostor")))
    }

    @Test func trustsThePathWhenNoBundleIdentifierWasRecorded() {
        let locator = StubApplicationLocator(existingPaths: [slackPath])
        let outcome = resolver(locator).resolve(DockTile(kind: .app, path: slackPath, label: "Slack"))
        #expect(outcome == .success(DockTile(kind: .app, path: slackPath, label: "Slack")))
    }

    @Test func expandsHomeRelativeFolderTilesForThisMachine() {
        let locator = StubApplicationLocator(existingPaths: ["/Users/bob/Downloads"])
        let outcome = resolver(locator)
            .resolve(DockTile(kind: .folder, path: "~/Downloads", label: "Downloads"))
        guard case let .success(tile) = outcome else {
            Issue.record("expected the folder to resolve")
            return
        }
        #expect(tile.path == "/Users/bob/Downloads")
    }

    @Test func spacersAndURLsAlwaysResolve() {
        let resolver = resolver(StubApplicationLocator())
        #expect(resolver.resolve(DockTile(kind: .spacer)) == .success(DockTile(kind: .spacer)))
        let link = DockTile(kind: .url, url: "https://github.com", label: "GitHub")
        #expect(resolver.resolve(link) == .success(link))
    }

    @Test func skipsMissingTilesAndKeepsTheRest() {
        let locator = StubApplicationLocator(bundleIDsByPath: [slackPath: slackID])
        let preset = Preset(apps: [
            .app(path: slackPath, label: "Slack", bundleID: slackID),
            .app(path: "/Applications/Nope.app", label: "Nope", bundleID: "com.example.nope"),
            DockTile(kind: .spacer),
        ])
        let resolution = resolver(locator).resolve(preset)
        #expect(resolution.state.apps.map(\.displayName) == ["Slack", "Spacer"])
        #expect(resolution.missing.count == 1)
        #expect(resolution.missing.first?.index == 1)
        #expect(resolution.missing.first?.reason == .notInstalled)
    }
}
