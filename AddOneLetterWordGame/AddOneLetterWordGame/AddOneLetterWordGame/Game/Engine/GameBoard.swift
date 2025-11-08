import Foundation

struct GameBoard: Equatable {
    let size: Int
    private(set) var tiles: [[TileState?]]

    init(size: Int) {
        self.size = size
        self.tiles = Array(repeating: Array(repeating: nil, count: size), count: size)
    }

    subscript(_ coordinate: BoardCoordinate) -> TileState? {
        get { tiles[coordinate.row][coordinate.column] }
        set { tiles[coordinate.row][coordinate.column] = newValue }
    }

    mutating func clearHighlights() {
        for row in 0..<size {
            for column in 0..<size {
                if let tile = tiles[row][column] {
                    tiles[row][column] = TileState(letter: tile.letter, isSeed: tile.isSeed, isNewlyPlaced: false)
                }
            }
        }
    }

    func filledNeighbors(of coordinate: BoardCoordinate) -> [BoardCoordinate] {
        coordinate.neighbors(within: size).filter { self[$0] != nil }
    }

    func hasFilledNeighbor(_ coordinate: BoardCoordinate) -> Bool {
        !filledNeighbors(of: coordinate).isEmpty
    }

    var filledCoordinates: [BoardCoordinate] {
        var positions: [BoardCoordinate] = []
        for row in 0..<size {
            for column in 0..<size {
                if tiles[row][column] != nil {
                    positions.append(BoardCoordinate(row: row, column: column))
                }
            }
        }
        return positions
    }

    func isFull() -> Bool {
        filledCoordinates.count == size * size
    }

    func toSnapshot(marking coordinate: BoardCoordinate?) -> [[TileState?]] {
        var snapshot = tiles
        if let coordinate {
            if let tile = self[coordinate] {
                snapshot[coordinate.row][coordinate.column] = TileState(letter: tile.letter, isSeed: tile.isSeed, isNewlyPlaced: true)
            }
        }
        return snapshot
    }
}
