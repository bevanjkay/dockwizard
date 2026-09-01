import SwiftUI

@main
struct DockWizardApp: App {
    @State private var editor = EditorModel()

    var body: some Scene {
        Window("DockWizard", id: "main") {
            EditorView(editor: editor)
                .frame(minWidth: 820, minHeight: 520)
        }
        .commands {
            CommandGroup(after: .saveItem) {
                Button("Apply to Dock") { editor.requestApply() }
                    .keyboardShortcut("r", modifiers: [.command])
                    .disabled(!editor.hasStagedChanges)
                Button("Revert Staged Changes") { editor.revert() }
                    .keyboardShortcut("z", modifiers: [.command, .shift])
                    .disabled(!editor.hasStagedChanges)
            }
        }

        Settings {
            SettingsView()
        }
    }
}
