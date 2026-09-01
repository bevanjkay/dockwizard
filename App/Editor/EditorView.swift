import DockCore
import SwiftUI

struct EditorView: View {
    @Bindable var editor: EditorModel

    var body: some View {
        NavigationSplitView {
            PresetSidebar(editor: editor)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 320)
        } detail: {
            tileList
                .safeAreaInset(edge: .top, spacing: 0) { banners }
                .safeAreaInset(edge: .bottom, spacing: 0) { statusBar }
        }
        .toolbar { toolbar }
        .sheet(item: $editor.sheet) { sheet in
            switch sheet {
            case .confirmMissing:
                MissingAppsSheet(editor: editor)
            case .addApplication:
                AppBrowserSheet(editor: editor)
            case let .savePreset(tiles):
                SavePresetSheet(editor: editor, tiles: tiles)
            case .moveToPosition:
                MoveToPositionSheet(editor: editor)
            }
        }
    }

    private var tileList: some View {
        List(selection: $editor.selection) {
            ForEach(DockState.Section.allCases, id: \.self) { section in
                Section(header: sectionHeader(section)) {
                    ForEach(Array(editor[section].enumerated()), id: \.element.id) { offset, item in
                        TileRow(item: item, position: offset + 1)
                    }
                    .onMove { offsets, destination in
                        editor.move(section, from: offsets, to: destination)
                    }
                }
            }
        }
        .contextMenu(forSelectionType: TileItem.ID.self) { _ in
            Button("Remove", systemImage: "trash", role: .destructive) { editor.removeSelection() }
            Button("Wrap in Spacers", systemImage: "rectangle.split.3x1") { editor.wrapSelectionInSpacers() }
            Button("Move to Position…", systemImage: "arrow.up.arrow.down") { editor.sheet = .moveToPosition }
            Divider()
            Button("Extract to New Preset…", systemImage: "square.and.arrow.down") {
                editor.sheet = .savePreset(tiles: editor.selectedTiles)
            }
        }
        .listStyle(.inset)
    }

    private func sectionHeader(_ section: DockState.Section) -> some View {
        HStack {
            Text(section == .apps ? "Applications" : "Folders & Links")
            Spacer()
            Text("\(editor[section].count)")
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private var banners: some View {
        if !editor.missing.isEmpty {
            Banner(
                icon: "exclamationmark.triangle.fill",
                tint: .orange,
                title: "\(editor.missing.count) item(s) in this preset aren't on this Mac",
                detail: editor.missing.map(\.description).joined(separator: ", ")
            )
        }
        ForEach(editor.warnings, id: \.self) { warning in
            Banner(icon: "info.circle.fill", tint: .secondary, title: warning, detail: nil)
        }
    }

    @ViewBuilder
    private var statusBar: some View {
        Divider()
        HStack(spacing: 12) {
            if let status = editor.status {
                Image(systemName: statusSymbol(status))
                    .foregroundStyle(statusTint(status))
                Text(status.message)
                    .font(.callout)
                    .lineLimit(1)
            } else if editor.hasStagedChanges {
                Image(systemName: "pencil.circle.fill").foregroundStyle(.blue)
                Text(changeSummary).font(.callout)
            } else {
                Text("The Dock matches this list.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let name = editor.loadedPresetName {
                Text(name).font(.callout).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var changeSummary: String {
        let diff = editor.diff
        let added = diff.sections.reduce(0) { $0 + $1.added.count }
        let removed = diff.sections.reduce(0) { $0 + $1.removed.count }
        let reordered = diff.sections.contains(where: \.reordered)
        var parts: [String] = []
        if added > 0 {
            parts.append("\(added) added")
        }
        if removed > 0 {
            parts.append("\(removed) removed")
        }
        if reordered {
            parts.append("reordered")
        }
        if !diff.settings.isEmpty {
            parts.append("\(diff.settings.count) setting(s)")
        }
        return parts.isEmpty ? "Staged changes" : "Staged: " + parts.joined(separator: ", ")
    }

    private func statusSymbol(_ status: EditorModel.Status) -> String {
        switch status {
        case .info: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .failure: "xmark.octagon.fill"
        }
    }

    private func statusTint(_ status: EditorModel.Status) -> Color {
        switch status {
        case .info: .green
        case .warning: .orange
        case .failure: .red
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup {
            Button("Add", systemImage: "plus") { editor.sheet = .addApplication }
                .help("Add an application, folder or spacer")

            Menu("Insert Spacer", systemImage: "rectangle.split.3x1") {
                Button("Spacer") { editor.insert(DockTile(kind: .spacer), into: .apps) }
                Button("Small Spacer") { editor.insert(DockTile(kind: .smallSpacer), into: .apps) }
                Button("Flexible Spacer") { editor.insert(DockTile(kind: .flexSpacer), into: .apps) }
            }
            .help("A flexible spacer expands to fill the whole Dock")

            Button("Remove", systemImage: "minus") { editor.removeSelection() }
                .disabled(editor.selection.isEmpty)

            Spacer()

            Button("Reload", systemImage: "arrow.clockwise") { editor.reloadFromDock() }
                .help("Discard staged edits and read the Dock again")

            Button("Revert", systemImage: "arrow.uturn.backward") { editor.revert() }
                .disabled(!editor.hasStagedChanges)

            Button("Save Preset…", systemImage: "square.and.arrow.down") {
                editor.sheet = .savePreset(tiles: nil)
            }

            Button("Apply", systemImage: "checkmark.circle") { editor.requestApply() }
                .disabled(!editor.hasStagedChanges)
                .keyboardShortcut("r", modifiers: .command)
                .help("Write these tiles to the Dock and restart it")
        }
    }
}

struct Banner: View {
    let icon: String
    let tint: Color
    let title: String
    let detail: String?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.4))
    }
}
