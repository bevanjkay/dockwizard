# Agent notes

## Build & test
- `make generate` regenerates `DockWizard.xcodeproj` from `project.yml` (XcodeGen). Commit both after changing `project.yml`.
- `make build` builds the app; `make test` runs the SwiftPM tests in `Packages/DockWizardKit`; `make cli` builds the `dockwizard` binary alone.
- `make lint` runs `swiftformat --lint` and `swiftlint`.
- Core logic lives in `Packages/DockWizardKit`; keep AppKit/SwiftUI out of `DockCore` and `PresetCore` so they stay testable with `swift test`. The one exception is `SystemApplicationLocator`, which wraps `NSWorkspace` behind the `ApplicationLocator` protocol.
- CI runs `zizmor` and `actionlint` over `.github/`; every action must be commit-pinned with a `# <tag>` comment. Run both locally before pushing workflow changes.
- Add remote SwiftPM dependencies to `Packages/DockWizardKit`, not the app target: the app's `Package.resolved` lands under the gitignored `*.xcodeproj/**/swiftpm/`, where Dependabot and osv-scanner never see it.

## Conventions
- Swift 6 strict concurrency; new types should be `Sendable` or isolated to `@MainActor`.
- Minimum macOS 26; bundle ID `me.bevankay.dockwizard`; CLI binary `dockwizard`.
- The app is **not** sandboxed. A sandboxed process cannot write another application's preference domain, so the Mac App Store is not a distribution option.
- Presets, backups and settings live under `~/Library/Application Support/DockWizard/`.

## Working with the Dock
- **Never read or write `~/Library/Preferences/com.apple.dock.plist` directly.** `cfprefsd` caches the domain: a file read can return stale data (this bit us during development — three tiles that had been written correctly appeared to be missing), and a file write can be silently clobbered. Everything goes through `CFPreferences`, i.e. `CFPreferencesStore`.
- A tile only needs `tile-type`, `file-data._CFURLString` and `file-label`. The Dock regenerates `GUID`, the `book` bookmark blob, `bundle-identifier`, `file-type` and the modification dates on next launch. **Never write `book`** — it encodes volume UUID and inode, and is what would make presets non-portable.
- A tile pointing at a path that does not exist is *retained*, not dropped, and tiles after it keep their index. Skipping unresolvable tiles is a UX choice, not a correctness requirement.
- Verified on macOS 26.6: `url-tile` lives in `persistent-others` and uses `label` + `url._CFURLString` (not `file-label`/`file-data`); `spacer-tile`, `small-spacer-tile` and `flex-spacer-tile` all round-trip.
- The folder-tile integers (`showas`, `displayas`, `arrangement`) follow the `dockutil` convention and are mapped to named enums in `FolderOptions`. They round-trip correctly but the *labels* have not been confirmed against the Dock's own context menu.

## Testing against a real Dock
- `make dock-snapshot` before experimenting, `make dock-restore` to put it back. The snapshot lives in `~/Library/Application Support/DockWizard/pristine/` and is never pruned (unlike `backups/`, which keeps the last 10).
- A **flexible spacer** expands to fill all available width. Adding one makes the Dock stretch across the entire screen and look catastrophically broken while behaving exactly as designed. Do not add one to a Dock someone is using without warning them first.
- Every apply calls `killall Dock`, which blacks the Dock out for about a second. This is why the GUI stages edits behind an explicit Apply rather than writing on every drag.

## Releases
- `Scripts/package.sh [version]` builds the universal CLI, embeds it in the app bundle, then archives, signs and writes DMG/zip/SHA256SUMS to `dist/`. The embedded CLI must carry the same Developer ID identity and hardened runtime as the app or notarisation rejects the bundle.
- With `CODE_SIGN_IDENTITY="Developer ID Application"` + `DEVELOPMENT_TEAM` it signs for distribution; with `ASC_KEY_ID`/`ASC_ISSUER_ID`/`ASC_KEY_PATH` it also notarises and staples. Without them it falls back to ad-hoc.
- `release.yml` runs it on `v*` tags using the `DEVELOPER_ID_P12`, `DEVELOPER_ID_P12_PASSWORD`, `APPLE_TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` secrets, and marks tags containing `-` as pre-releases.
