import AppKit
import DockCore
import SwiftUI

struct SettingsView: View {
    @AppStorage(PreferenceKey.skipMissingAppsPrompt) private var skipMissingAppsPrompt = false
    @AppStorage(PreferenceKey.presetsDirectoryOverride) private var presetsDirectoryOverride = ""

    @State private var cliStatus: CommandLineTool.Status = .unknown

    var body: some View {
        Form {
            Section("Presets") {
                LabeledContent("Library") {
                    HStack {
                        Text(resolvedPresetsDirectory)
                            .lineLimit(1)
                            .truncationMode(.head)
                            .foregroundStyle(.secondary)
                        Button("Choose…") { chooseDirectory() }
                        if !presetsDirectoryOverride.isEmpty {
                            Button("Reset") { presetsDirectoryOverride = "" }
                        }
                    }
                }
                Text("Point this at a dotfiles repository to keep presets in version control. "
                    + "DOCKWIZARD_PRESETS_DIR overrides this for the command line tool.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Applying") {
                Toggle("Don't ask again when apps are missing", isOn: $skipMissingAppsPrompt)
                Text("Skipped items are always reported after applying, whether or not this is on.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Command Line Tool") {
                LabeledContent("dockwizard") {
                    HStack {
                        Text(cliStatus.description).foregroundStyle(.secondary)
                        switch cliStatus {
                        case .installed:
                            Button("Remove") { cliStatus = CommandLineTool.uninstall() }
                        default:
                            Button("Install…") { cliStatus = CommandLineTool.install() }
                        }
                    }
                }
                if case let .failed(message) = cliStatus {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .textSelection(.enabled)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 520)
        .task { cliStatus = CommandLineTool.status() }
    }

    private var resolvedPresetsDirectory: String {
        ApplicationPaths.presetsDirectory(override: presetsDirectoryOverride.isEmpty ? nil : presetsDirectoryOverride)
            .path
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.message = "Choose where DockWizard should keep presets."
        guard panel.runModal() == .OK, let url = panel.url else { return }
        presetsDirectoryOverride = url.path
    }
}
