import Foundation
import SwiftUI

/// Keys for the app's own preferences, kept in one place so the Settings screen and the
/// editor cannot drift apart.
enum PreferenceKey {
    /// Suppresses the confirmation sheet when a preset references apps that are not installed.
    /// The missing items are still listed after applying — this hides the dialog, never the fact.
    static let skipMissingAppsPrompt = "skipMissingAppsPrompt"
    /// Overrides the preset library location, so it can point at a dotfiles repository.
    static let presetsDirectoryOverride = "presetsDirectoryOverride"
}

extension AppStorage where Value == Bool {
    init(skipMissingAppsPrompt _: Void) {
        self.init(wrappedValue: false, PreferenceKey.skipMissingAppsPrompt)
    }
}
