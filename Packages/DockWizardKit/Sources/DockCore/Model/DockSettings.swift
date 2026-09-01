import Foundation

/// Dock-owned appearance settings.
///
/// Every field is optional: a preset may carry a partial set, in which case only the keys
/// present are written and the rest of the Dock is left untouched.
public struct DockSettings: Codable, Sendable, Equatable, Hashable {
    public var orientation: Orientation?
    public var tileSize: Double?
    public var largeSize: Double?
    public var magnification: Bool?
    public var autohide: Bool?
    public var autohideDelay: Double?
    public var autohideTimeModifier: Double?
    public var minimizeEffect: MinimizeEffect?
    public var minimizeToApplication: Bool?
    public var showRecents: Bool?
    public var showHidden: Bool?
    public var staticOnly: Bool?
    public var launchAnimation: Bool?

    public init(
        orientation: Orientation? = nil,
        tileSize: Double? = nil,
        largeSize: Double? = nil,
        magnification: Bool? = nil,
        autohide: Bool? = nil,
        autohideDelay: Double? = nil,
        autohideTimeModifier: Double? = nil,
        minimizeEffect: MinimizeEffect? = nil,
        minimizeToApplication: Bool? = nil,
        showRecents: Bool? = nil,
        showHidden: Bool? = nil,
        staticOnly: Bool? = nil,
        launchAnimation: Bool? = nil
    ) {
        self.orientation = orientation
        self.tileSize = tileSize
        self.largeSize = largeSize
        self.magnification = magnification
        self.autohide = autohide
        self.autohideDelay = autohideDelay
        self.autohideTimeModifier = autohideTimeModifier
        self.minimizeEffect = minimizeEffect
        self.minimizeToApplication = minimizeToApplication
        self.showRecents = showRecents
        self.showHidden = showHidden
        self.staticOnly = staticOnly
        self.launchAnimation = launchAnimation
    }

    public enum Orientation: String, Codable, Sendable, CaseIterable {
        case left, bottom, right
    }

    public enum MinimizeEffect: String, Codable, Sendable, CaseIterable {
        case genie, scale, suck
    }

    public var isEmpty: Bool { self == DockSettings() }
}
