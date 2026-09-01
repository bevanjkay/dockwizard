import Foundation

/// Read and write access to a single preferences domain.
///
/// Abstracted so the apply path can be unit-tested against an in-memory fake, and so CI can
/// exercise the real `CFPreferences` implementation against a throwaway domain.
public protocol PreferencesStore: Sendable {
    var domain: String { get }
    func value(forKey key: String) -> PlistValue?
    func setValue(_ value: PlistValue?, forKey key: String) throws
    /// Every key currently set in the domain, used for backups.
    func allValues() -> [String: PlistValue]
    /// Applies a batch of changes; `nil` values remove the key.
    func setValues(_ values: [String: PlistValue?]) throws
    /// Flushes pending changes to the preferences daemon.
    func synchronize() throws
}

public extension PreferencesStore {
    func setValue(_ value: PlistValue?, forKey key: String) throws {
        try setValues([key: value])
    }

    func setValues(_ values: [String: PlistValue?]) throws {
        for (key, value) in values {
            try setValue(value, forKey: key)
        }
    }
}

public enum PreferencesStoreError: Error, Equatable, LocalizedError {
    case synchronizationFailed(domain: String)

    public var errorDescription: String? {
        switch self {
        case let .synchronizationFailed(domain):
            "Could not write preferences for \(domain). Check that this process is not sandboxed."
        }
    }
}
