import AppKit
import DockCore
import SwiftUI

/// The icon shown next to a tile in the editor.
struct TileIcon: View {
    let tile: DockTile

    var body: some View {
        Group {
            if tile.kind.isSpacer {
                Image(systemName: symbol)
                    .foregroundStyle(.tertiary)
            } else if let image = fileIcon {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
            } else {
                Image(systemName: symbol)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 22, height: 22)
    }

    private var fileIcon: NSImage? {
        guard let path = tile.path, FileManager.default.fileExists(atPath: path) else { return nil }
        return NSWorkspace.shared.icon(forFile: path)
    }

    private var symbol: String {
        switch tile.kind {
        case .app: "app.dashed"
        case .file: "doc"
        case .folder: "folder"
        case .url: "globe"
        case .spacer: "rectangle.split.2x1"
        case .smallSpacer: "rectangle.compress.vertical"
        case .flexSpacer: "arrow.left.and.right"
        }
    }
}
