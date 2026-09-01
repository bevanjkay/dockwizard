import DockCore
import SwiftUI

struct SavePresetSheet: View {
    @Bindable var editor: EditorModel
    /// When non-nil these tiles are saved instead of the whole staged Dock — this is the
    /// "extract selection to a new preset" path.
    let tiles: [DockTile]?
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var includeSettings = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(tiles == nil ? "Save Preset" : "Extract \(tiles?.count ?? 0) tiles to a new preset")
                .font(.headline)

            TextField("Name", text: $name, prompt: Text("Work"))
                .textFieldStyle(.roundedBorder)
                .onSubmit(save)

            Toggle("Include Dock appearance settings", isOn: $includeSettings)
                .help("Size, position, magnification and hiding. Leave off for a tiles-only preset.")

            Text("Saved to \(editor.library.directory.path)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.middle)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(18)
        .frame(width: 420)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        editor.savePreset(named: trimmed, tiles: tiles, includeSettings: includeSettings)
        dismiss()
    }
}

struct MoveToPositionSheet: View {
    @Bindable var editor: EditorModel
    @Environment(\.dismiss) private var dismiss
    @State private var position = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Move Selection").font(.headline)
            Text("Positions are 1-indexed and count spacers, matching 'dockwizard list'.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Text("Move to position")
                TextField("", value: $position, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 70)
                Stepper("", value: $position, in: 1 ... 200).labelsHidden()
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Move") {
                    editor.moveSelection(toPosition: position)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(18)
        .frame(width: 380)
    }
}
