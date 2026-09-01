import DockCore
import PresetCore
import SwiftUI

struct PresetSidebar: View {
    @Bindable var editor: EditorModel
    @State private var confirmingDeletion: PresetLibrary.Entry?

    var body: some View {
        List {
            Section("Presets") {
                if editor.presets.isEmpty {
                    Text("No presets yet")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                }
                ForEach(editor.presets) { entry in
                    Label(entry.name, systemImage: "square.stack")
                        .badge(entry.name == editor.loadedPresetName ? "loaded" : nil)
                        .contentShape(Rectangle())
                        .onTapGesture { editor.loadPreset(entry) }
                        .contextMenu {
                            Button("Load") { editor.loadPreset(entry) }
                            Button("Reveal in Finder") {
                                NSWorkspace.shared.activateFileViewerSelecting([entry.url])
                            }
                            Divider()
                            Button("Delete", role: .destructive) { confirmingDeletion = entry }
                        }
                }
            }

            Section("Dock") {
                Button("Read Current Dock", systemImage: "arrow.clockwise") { editor.reloadFromDock() }
                Button("Restore Last Snapshot", systemImage: "clock.arrow.circlepath") {
                    editor.restoreMostRecentBackup()
                }
            }
            .buttonStyle(.plain)
        }
        .listStyle(.sidebar)
        .confirmationDialog(
            "Delete \(confirmingDeletion?.name ?? "")?",
            isPresented: Binding(
                get: { confirmingDeletion != nil },
                set: { if !$0 { confirmingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let entry = confirmingDeletion { editor.deletePreset(entry) }
                confirmingDeletion = nil
            }
            Button("Cancel", role: .cancel) { confirmingDeletion = nil }
        } message: {
            Text("The preset file is removed from disk. Your Dock is not changed.")
        }
    }
}
