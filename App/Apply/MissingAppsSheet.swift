import DockCore
import PresetCore
import SwiftUI

/// Shown before applying a preset that references apps this Mac does not have.
///
/// "Don't ask again" hides this sheet, never the outcome: the skipped items are still
/// reported in the status bar and stay listed in the banner above the tile list.
struct MissingAppsSheet: View {
    @Bindable var editor: EditorModel
    @AppStorage(PreferenceKey.skipMissingAppsPrompt) private var skipPrompt = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text("They'll be left out of the Dock. Everything else in this preset will be applied.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(18)

            Divider()

            List(Array(editor.missing.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 10) {
                    TileIcon(tile: item.tile)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.tile.displayName)
                        Text(item.reason.explanation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let path = item.tile.path {
                        Text(path)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.head)
                    }
                }
            }
            .frame(minHeight: 120, maxHeight: 220)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Don't ask again when apps are missing", isOn: $skipPrompt)
                    .help("Skipped items are still reported after applying. You can turn this back on in Settings.")

                HStack {
                    Spacer()
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                    Button("Apply Anyway") { editor.apply() }
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(18)
        }
        .frame(width: 540)
    }

    private var title: String {
        let count = editor.missing.count
        return count == 1
            ? "1 item in this preset isn't on this Mac"
            : "\(count) items in this preset aren't on this Mac"
    }
}
