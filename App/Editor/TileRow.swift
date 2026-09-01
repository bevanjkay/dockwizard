import DockCore
import SwiftUI

struct TileRow: View {
    let item: TileItem
    let position: Int

    var body: some View {
        HStack(spacing: 10) {
            Text("\(position)")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 24, alignment: .trailing)

            TileIcon(tile: item.tile)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.tile.displayName)
                    .font(.body)
                    .foregroundStyle(item.tile.kind.isSpacer ? .secondary : .primary)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer(minLength: 0)

            if !exists {
                Label("Not on this Mac", systemImage: "exclamationmark.triangle.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.orange)
                    .help("Nothing exists at \(item.tile.path ?? "this path") — the Dock will show a placeholder.")
            }
        }
        .padding(.vertical, 2)
    }

    private var detail: String? {
        item.tile.url ?? item.tile.path
    }

    private var exists: Bool {
        guard let path = item.tile.path else { return true }
        return FileManager.default.fileExists(atPath: path)
    }
}
