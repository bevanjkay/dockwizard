import DockCore
import Foundation
import Testing

struct ApplicationPathsTests {
    @Test func honoursTheEnvironmentOverride() {
        let url = ApplicationPaths.presetsDirectory(
            environment: ["DOCKWIZARD_PRESETS_DIR": "/tmp/dotfiles/dock"]
        )
        #expect(url.path == "/tmp/dotfiles/dock")
    }

    @Test func anExplicitOverrideBeatsTheEnvironment() {
        let url = ApplicationPaths.presetsDirectory(
            override: "/tmp/explicit",
            environment: ["DOCKWIZARD_PRESETS_DIR": "/tmp/from-env"]
        )
        #expect(url.path == "/tmp/explicit")
    }

    @Test func fallsBackToApplicationSupport() {
        let url = ApplicationPaths.presetsDirectory(environment: [:])
        #expect(url.path.hasSuffix("Application Support/DockWizard/presets"))
    }
}
