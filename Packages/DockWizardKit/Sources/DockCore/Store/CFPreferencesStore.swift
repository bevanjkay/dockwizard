import Foundation

/// The real preferences store, backed by `CFPreferences`.
///
/// Writing `~/Library/Preferences/com.apple.dock.plist` directly is unreliable: `cfprefsd`
/// caches the domain and will happily overwrite a file written behind its back. Every read
/// and write therefore goes through the preferences API.
public struct CFPreferencesStore: PreferencesStore {
    public let domain: String

    public init(domain: String) {
        self.domain = domain
    }

    public static let dock = CFPreferencesStore(domain: DockKeys.domain)

    private var applicationID: CFString {
        domain as CFString
    }

    public func value(forKey key: String) -> PlistValue? {
        guard let object = CFPreferencesCopyAppValue(key as CFString, applicationID) else { return nil }
        return PlistValue(propertyList: object)
    }

    public func allValues() -> [String: PlistValue] {
        let keys = CFPreferencesCopyKeyList(
            applicationID,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        ) as? [String] ?? []
        var result: [String: PlistValue] = [:]
        for key in keys {
            if let value = value(forKey: key) {
                result[key] = value
            }
        }
        return result
    }

    public func setValues(_ values: [String: PlistValue?]) throws {
        for (key, value) in values {
            CFPreferencesSetAppValue(key as CFString, value?.propertyListObject as CFPropertyList?, applicationID)
        }
        try synchronize()
    }

    public func synchronize() throws {
        guard CFPreferencesAppSynchronize(applicationID) else {
            throw PreferencesStoreError.synchronizationFailed(domain: domain)
        }
    }
}
