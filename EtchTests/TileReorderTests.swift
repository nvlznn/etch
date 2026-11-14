import CoreGraphics
import Foundation
import Testing
@testable import Etch

struct TileReorderTests {
    let tile = CGSize(width: 118, height: 118)

    @Test func middleOfATileMoves() {
        #expect(TileReorder.shouldMove(at: CGPoint(x: 59, y: 59), in: tile))
        #expect(TileReorder.shouldMove(at: CGPoint(x: 40, y: 80), in: tile))
    }

    /// Held on the line between two rows, a move puts the neighbour under the finger, which moves
    /// the tile straight back, forever. Edges and corners must not count.
    @Test func edgesAndCornersDoNotMove() {
        #expect(!TileReorder.shouldMove(at: CGPoint(x: 57, y: 121), in: tile))
        #expect(!TileReorder.shouldMove(at: CGPoint(x: 15, y: 6), in: tile))
        #expect(!TileReorder.shouldMove(at: CGPoint(x: 59, y: 4), in: tile))
        #expect(!TileReorder.shouldMove(at: CGPoint(x: 2, y: 59), in: tile))
    }

    /// Right after a move the tiles are still sliding, so the one passing under the finger isn't a
    /// real target yet. Moving again for it undoes the move, over and over.
    @Test func tilesMustSettleBetweenMoves() {
        let moved = Date("2026-11-14T05:00:00Z")
        #expect(!TileReorder.hasSettled(since: moved, at: moved.addingTimeInterval(0.02)))
        #expect(!TileReorder.hasSettled(since: moved, at: moved.addingTimeInterval(0.3)))
        #expect(TileReorder.hasSettled(since: moved, at: moved.addingTimeInterval(0.4)))
        #expect(TileReorder.hasSettled(since: .distantPast))
    }

    @Test func anUnmeasuredTileStillMoves() {
        #expect(TileReorder.shouldMove(at: CGPoint(x: 1, y: 1), in: .zero))
    }
}
