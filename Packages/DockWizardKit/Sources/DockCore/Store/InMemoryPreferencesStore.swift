import Foundation

/// An in-memory `PreferencesStore` for tests.
public final class InMemoryPreferencesStore: PreferencesStore, @unchecked Sendable {
    public let domain: String
    private let lock = NSLock()
    private var storage: [String: PlistValue]
    public private(set) var synchronizeCount = 0

    public init(domain: String = DockKeys.domain, initialValues: [String: PlistValue] = [:]) {
        self.domain = domain
        storage = initialValues
    }

    public func value(forKey key: String) -> PlistValue? {
        lock.withLock { storage[key] }
    }

    public func allValues() -> [String: PlistValue] {
        lock.withLock { storage }
    }

    public func setValues(_ values: [String: PlistValue?]) throws {
        lock.withLock {
            for (key, value) in values {
                storage[key] = value
            }
        }
        try synchronize()
    }

    public func synchronize() throws {
        lock.withLock { synchronizeCount += 1 }
    }
}
