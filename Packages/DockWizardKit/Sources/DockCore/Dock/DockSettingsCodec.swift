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
    /// the Dock untouched.
    public static func encode(_ settings: DockSettings) -> [String: PlistValue] {
        var values: [String: PlistValue] = [:]
        if let value = settings.orientation { values[DockKeys.orientation] = .string(value.rawValue) }
        if let value = settings.tileSize { values[DockKeys.tileSize] = .double(value) }
        if let value = settings.largeSize { values[DockKeys.largeSize] = .double(value) }
        if let value = settings.magnification { values[DockKeys.magnification] = .bool(value) }
        if let value = settings.autohide { values[DockKeys.autohide] = .bool(value) }
        if let value = settings.autohideDelay { values[DockKeys.autohideDelay] = .double(value) }
        if let value = settings.autohideTimeModifier { values[DockKeys.autohideTimeModifier] = .double(value) }
        if let value = settings.minimizeEffect { values[DockKeys.minimizeEffect] = .string(value.rawValue) }
        if let value = settings.minimizeToApplication { values[DockKeys.minimizeToApplication] = .bool(value) }
        if let value = settings.showRecents { values[DockKeys.showRecents] = .bool(value) }
        if let value = settings.showHidden { values[DockKeys.showHidden] = .bool(value) }
        if let value = settings.staticOnly { values[DockKeys.staticOnly] = .bool(value) }
        if let value = settings.launchAnimation { values[DockKeys.launchAnimation] = .bool(value) }
        return values
    }
}
