import AppKit
import DockCore
import SwiftUI

struct AppBrowserSheet: View {
    @Bindable var editor: EditorModel
    @Environment(\.dismiss) private var dismiss

    @State private var applications: [InstalledApplication] = []
    @State private var query = ""
    @State private var selection: Set<InstalledApplication.ID> = []
    @State private var isScanning = true

    private var filtered: [InstalledApplication] {
        guard !query.isEmpty else { return applications }
        return applications.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add to the Dock").font(.headline)
                Spacer()
                Button("Choose in Finder…", action: chooseInFinder)
            }
            .padding(14)

            Divider()

            List(filtered, selection: $selection) { application in
                HStack(spacing: 10) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: application.path))
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text(application.name)
                    Spacer()
                    Text(application.url.deletingLastPathComponent().path)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.head)
                }
                .tag(application.id)
            }
            .overlay {
                if isScanning {
                    ProgressView("Looking for applications…")
                } else if filtered.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .searchable(text: $query, placement: .toolbar, prompt: "Search applications")

            Divider()

            HStack {
                Text("\(applications.count) applications found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Add") { addSelection() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(selection.isEmpty)
            }
            .padding(14)
        }
        .frame(width: 620, height: 460)
        .task {
            applications = await InstalledApplications.scan()
            isScanning = false
        }
    }

    private func addSelection() {
        for application in applications where selection.contains(application.id) {
            editor.insert(
                DockTile(
                    kind: .app,
                    path: application.path,
                    label: application.name,
                    bundleID: application.bundleID
                ),
                into: .apps
            )
        }
        dismiss()
    }

    /// The escape hatch for anything not in an Applications folder — including folders and
    /// documents, which belong in the other section.
    private func chooseInFinder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.message = "Choose applications, folders or files to add to the Dock."
        guard panel.runModal() == .OK else { return }

        for url in panel.urls {
            let isBundle = url.pathExtension == "app"
            var isDirectory: ObjCBool = false
            _ = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
            let kind: TileKind = isBundle ? .app : (isDirectory.boolValue ? .folder : .file)
            editor.insert(
                DockTile(
                    kind: kind,
                    path: url.path,
                    label: isBundle ? url.deletingPathExtension().lastPathComponent : url.lastPathComponent,
                    bundleID: isBundle ? Bundle(url: url)?.bundleIdentifier : nil
                ),
                into: kind == .app ? .apps : .others
            )
        }
        dismiss()
    }
}
