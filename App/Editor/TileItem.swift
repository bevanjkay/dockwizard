import DockCore
import Foundation

/// A `DockTile` with a stable identity, so SwiftUI can track rows across reorders.
///
/// Identity is deliberately not part of `DockTile` itself: two tiles pointing at the same
/// app are equal in the model, and the diff engine relies on that.
struct TileItem: Identifiable, Hashable {
    let id: UUID
    var tile: DockTile

    init(_ tile: DockTile, id: UUID = UUID()) {
        self.id = id
        self.tile = tile
    }
}

extension [TileItem] {
    var tiles: [DockTile] { map(\.tile) }

    init(_ tiles: [DockTile]) {
        self = tiles.map { TileItem($0) }
    }
}
