import Foundation

/// Translates between `DockSettings` and the flat appearance keys in `com.apple.dock`.
public enum DockSettingsCodec {
    public static func decode(from store: PreferencesStore) -> DockSettings {
        DockSettings(
            orientation: store.value(forKey: DockKeys.orientation)?.stringValue
                .flatMap(DockSettings.Orientation.init(rawValue:)),
            tileSize: store.value(forKey: DockKeys.tileSize)?.doubleValue,
            largeSize: store.value(forKey: DockKeys.largeSize)?.doubleValue,
            magnification: store.value(forKey: DockKeys.magnification)?.boolValue,
            autohide: store.value(forKey: DockKeys.autohide)?.boolValue,
            autohideDelay: store.value(forKey: DockKeys.autohideDelay)?.doubleValue,
            autohideTimeModifier: store.value(forKey: DockKeys.autohideTimeModifier)?.doubleValue,
            minimizeEffect: store.value(forKey: DockKeys.minimizeEffect)?.stringValue
                .flatMap(DockSettings.MinimizeEffect.init(rawValue:)),
            minimizeToApplication: store.value(forKey: DockKeys.minimizeToApplication)?.boolValue,
            showRecents: store.value(forKey: DockKeys.showRecents)?.boolValue,
            showHidden: store.value(forKey: DockKeys.showHidden)?.boolValue,
            staticOnly: store.value(forKey: DockKeys.staticOnly)?.boolValue,
            launchAnimation: store.value(forKey: DockKeys.launchAnimation)?.boolValue
        )
    }

    /// Only keys present in `settings` are emitted, so a partial preset leaves the rest of
    /// the Dock untouched. Assigning `nil` to a dictionary subscript removes the key, so an
    /// absent setting simply never appears.
    public static func encode(_ settings: DockSettings) -> [String: PlistValue] {
        var values: [String: PlistValue] = [:]
        values[DockKeys.orientation] = settings.orientation.map { .string($0.rawValue) }
        values[DockKeys.minimizeEffect] = settings.minimizeEffect.map { .string($0.rawValue) }
        values[DockKeys.tileSize] = settings.tileSize.map(PlistValue.double)
        values[DockKeys.largeSize] = settings.largeSize.map(PlistValue.double)
        values[DockKeys.autohideDelay] = settings.autohideDelay.map(PlistValue.double)
        values[DockKeys.autohideTimeModifier] = settings.autohideTimeModifier.map(PlistValue.double)
        values[DockKeys.magnification] = settings.magnification.map(PlistValue.bool)
        values[DockKeys.autohide] = settings.autohide.map(PlistValue.bool)
        values[DockKeys.minimizeToApplication] = settings.minimizeToApplication.map(PlistValue.bool)
        values[DockKeys.showRecents] = settings.showRecents.map(PlistValue.bool)
        values[DockKeys.showHidden] = settings.showHidden.map(PlistValue.bool)
        values[DockKeys.staticOnly] = settings.staticOnly.map(PlistValue.bool)
        values[DockKeys.launchAnimation] = settings.launchAnimation.map(PlistValue.bool)
        return values
    }
}
