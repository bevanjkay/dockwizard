# DockWizard

A macOS Dock manager with portable presets, a GUI for bulk editing, and a CLI for scripting.

Save your Dock as a JSON file, keep it in your dotfiles, and put it back on any Mac. Apps that
aren't installed on the new machine are reported rather than silently mangling the layout.

- **Presets** — capture the Dock to versioned JSON and apply it back, tiles and appearance.
- **Bulk editing** — multi-select, drag to reorder a whole block, wrap a run of apps in
  spacers, extract a selection into a new preset.
- **Staged edits** — nothing touches the Dock until you press Apply, because every write
  restarts the Dock.
- **Portable** — apps are matched by bundle identifier with a verified path, and `$HOME` is
  tokenised so `~/Downloads` works under a different username.
- **Reversible** — every apply snapshots the whole Dock preference domain first.

## Install

```sh
brew install --cask bevanjkay/tap/dockwizard   # once released
```

Or grab the DMG from [Releases](https://github.com/bevanjkay/dockwizard/releases). The app
bundles the `dockwizard` CLI; install it onto your `PATH` from **Settings → Command Line Tool**.

## CLI

```sh
dockwizard export --save work        # capture the current Dock into the preset library
dockwizard list                      # show Dock tiles with their positions
dockwizard presets                   # show presets in the library
dockwizard diff work                 # what would change
dockwizard apply work                # replace the Dock with the preset
dockwizard apply work --dry-run      # same, without writing
dockwizard restore                   # roll back to the snapshot from the last apply
```

Positions are **1-indexed and count spacers**, matching the order the Dock stores them:

```sh
dockwizard add /Applications/Slack.app --position 3
dockwizard add com.apple.Safari --start
dockwizard add spacer --end
dockwizard add https://github.com          # URL tiles go to the folders section
dockwizard remove Trello
dockwizard move 5 2
```

Exit codes: `0` success, `2` applied with items skipped, `1` error. Add `--strict` to change
nothing unless everything resolves, or `--quiet` to exit `0` regardless.

### Preset location

Presets live in `~/Library/Application Support/DockWizard/presets/`. Point that at a dotfiles
repository with `DOCKWIZARD_PRESETS_DIR`, `--presets-dir`, or **Settings → Presets → Library**.
Any command that takes a preset name also takes a path.

## Preset format

```json
{
  "schemaVersion": 1,
  "generator": "dockwizard/0.2.0",
  "name": "Work",
  "description": "Dev and comms, no Adobe",
  "apps": [
    { "type": "app", "bundleId": "com.tinyspeck.slackmacgap",
      "path": "/Applications/Slack.app", "label": "Slack" },
    { "type": "spacer" }
  ],
  "others": [
    { "type": "folder", "path": "~/Downloads", "label": "Downloads",
      "folder": { "showAs": "fan", "displayAs": "folder",
                  "arrangement": "dateAdded", "itemSize": null } },
    { "type": "url", "url": "https://github.com", "label": "GitHub" }
  ],
  "settings": {
    "orientation": "bottom", "tileSize": 48, "magnification": false,
    "autohide": false, "minimizeEffect": "genie", "showRecents": false
  }
}
```

`apps` and `others` mirror the Dock's two lists either side of the divider. Tile types are
`app`, `file`, `folder`, `url`, `spacer`, `smallSpacer` and `flexSpacer`. Folder display
options live in a nested `folder` object, because they only mean anything on a folder tile —
`itemSize: null` is the Dock's "automatic".

`settings` is **optional and partial**: only the keys present are written, so a tiles-only
preset leaves your Dock's size and position alone. Unknown keys are ignored with a warning
rather than failing, but a `schemaVersion` newer than your build is an error.

### Missing apps

Applying resolves each app by its recorded path (verified against the expected bundle
identifier, so a stale copy on a mounted disk image can't win), then by LaunchServices, then
gives up and reports it. The GUI asks before dropping anything; the CLI warns on stderr and
exits `2`.

## How it works

The Dock is configured entirely through the `com.apple.dock` preference domain, and there is
no public API for it. DockWizard writes through `CFPreferences` and restarts the Dock.

A tile only needs three keys — `tile-type`, `file-data._CFURLString` and `file-label`. The
Dock regenerates `GUID`, `bundle-identifier` and the `book` bookmark blob itself on next
launch. That last one matters: `book` encodes a volume UUID and inode, so a preset containing
one would be worthless on any other machine. DockWizard never writes it.

## Building

Requires Xcode 26 and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
make generate   # DockWizard.xcodeproj from project.yml
make build      # build the app
make test       # SwiftPM tests
make cli        # just the CLI
make lint       # swiftformat --lint + swiftlint
```

Developing against your own Dock? `make dock-snapshot` first and `make dock-restore` to undo.
Be careful with flexible spacers — one will stretch your Dock across the entire screen, which
looks like catastrophic corruption and is merely the tile doing its job.

## Not the Mac App Store

A sandboxed process cannot write another application's preference domain, so DockWizard cannot
be sandboxed and cannot ship on the App Store. Releases are signed with a Developer ID and
notarised by Apple.

## Licence

MIT.
