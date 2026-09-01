import DockCore
import Foundation
import Testing

struct PlistValueTests {
    @Test func bridgesBooleansWithoutCollapsingThemToNumbers() {
        let value = PlistValue(propertyList: true as NSNumber)
        #expect(value == .bool(true))
        #expect(PlistValue(propertyList: 1 as NSNumber) == .int(1))
        #expect(PlistValue(propertyList: 0.5 as NSNumber) == .double(0.5))
    }

    @Test func roundTripsNestedStructures() throws {
        let original = PlistValue.dictionary([
            "tile-type": .string("file-tile"),
            "tile-data": .dictionary([
                "file-label": .string("Slack"),
                "file-data": .dictionary(["_CFURLStringType": .int(15)]),
            ]),
            "flags": .array([.bool(false), .int(3)]),
        ])
        let bridged = try #require(PlistValue(propertyList: original.propertyListObject))
        #expect(bridged == original)
    }

    @Test func subscriptReachesIntoDictionaries() {
        let value = PlistValue.dictionary(["a": .dictionary(["b": .string("c")])])
        #expect(value["a"]?["b"]?.stringValue == "c")
        #expect(value["missing"] == nil)
    }
}
