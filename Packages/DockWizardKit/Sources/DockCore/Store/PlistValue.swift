import Foundation

/// A `Sendable` stand-in for a property-list value.
///
/// The preferences APIs deal in `Any`, which cannot cross isolation boundaries under Swift 6
/// strict concurrency. Everything above the store boundary works with `PlistValue` instead,
/// and conversion to and from `CFPropertyList` happens only inside the store implementations.
public indirect enum PlistValue: Sendable, Equatable, Hashable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case date(Date)
    case data(Data)
    case array([PlistValue])
    case dictionary([String: PlistValue])

    public var boolValue: Bool? {
        switch self {
        case let .bool(value): value
        case let .int(value): value != 0
        case let .double(value): value != 0
        default: nil
        }
    }

    public var intValue: Int? {
        switch self {
        case let .int(value): value
        case let .double(value): Int(value)
        case let .bool(value): value ? 1 : 0
        default: nil
        }
    }

    public var doubleValue: Double? {
        switch self {
        case let .double(value): value
        case let .int(value): Double(value)
        case let .bool(value): value ? 1 : 0
        default: nil
        }
    }

    public var stringValue: String? {
        guard case let .string(value) = self else { return nil }
        return value
    }

    public var arrayValue: [PlistValue]? {
        guard case let .array(value) = self else { return nil }
        return value
    }

    public var dictionaryValue: [String: PlistValue]? {
        guard case let .dictionary(value) = self else { return nil }
        return value
    }

    public subscript(key: String) -> PlistValue? {
        dictionaryValue?[key]
    }
}

public extension PlistValue {
    /// Bridges a `CFPropertyList` value into the `Sendable` representation.
    ///
    /// `NSNumber` cannot distinguish a stored boolean from `0`/`1` by type alone, so the
    /// underlying CFNumber type is inspected — the Dock stores several genuine booleans.
    init?(propertyList object: Any) {
        switch object {
        case let value as String:
            self = .string(value)
        case let value as Data:
            self = .data(value)
        case let value as Date:
            self = .date(value)
        case let value as NSNumber:
            if CFGetTypeID(value) == CFBooleanGetTypeID() {
                self = .bool(value.boolValue)
            } else if CFNumberIsFloatType(value) {
                self = .double(value.doubleValue)
            } else {
                self = .int(value.intValue)
            }
        case let value as [Any]:
            self = .array(value.compactMap { PlistValue(propertyList: $0) })
        case let value as [String: Any]:
            var result: [String: PlistValue] = [:]
            for (key, element) in value {
                if let converted = PlistValue(propertyList: element) { result[key] = converted }
            }
            self = .dictionary(result)
        default:
            return nil
        }
    }

    /// The `CFPropertyList`-compatible object for this value.
    var propertyListObject: Any {
        switch self {
        case let .bool(value): value as CFBoolean
        case let .int(value): value as NSNumber
        case let .double(value): value as NSNumber
        case let .string(value): value as NSString
        case let .date(value): value as NSDate
        case let .data(value): value as NSData
        case let .array(value): value.map(\.propertyListObject) as NSArray
        case let .dictionary(value): value.mapValues(\.propertyListObject) as NSDictionary
        }
    }
}
