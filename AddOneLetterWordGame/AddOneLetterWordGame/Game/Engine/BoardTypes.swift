import Foundation

struct BoardCoordinate: Hashable, Codable {
    let row: Int
    let column: Int

    func neighbors(within size: Int) -> [BoardCoordinate] {
        let candidates = [
            BoardCoordinate(row: row - 1, column: column),
            BoardCoordinate(row: row + 1, column: column),
            BoardCoordinate(row: row, column: column - 1),
            BoardCoordinate(row: row, column: column + 1)
        ]
        return candidates.filter { $0.isValid(for: size) }
    }

    func isValid(for size: Int) -> Bool {
        row >= 0 && column >= 0 && row < size && column < size
    }

    func manhattanDistance(to other: BoardCoordinate) -> Int {
        abs(row - other.row) + abs(column - other.column)
    }
}

struct TileState: Equatable, Codable {
    let letter: Character
    let isSeed: Bool
    let isNewlyPlaced: Bool

    init(letter: Character, isSeed: Bool = false, isNewlyPlaced: Bool = false) {
        self.letter = letter
        self.isSeed = isSeed
        self.isNewlyPlaced = isNewlyPlaced
    }
}

struct WordPath: Equatable {
    struct Node: Equatable {
        let coordinate: BoardCoordinate
        let letter: Character
    }

    let nodes: [Node]

    init(nodes: [Node]) {
        self.nodes = nodes
    }

    var word: String { String(nodes.map { $0.letter }) }

    func contains(_ coordinate: BoardCoordinate) -> Bool {
        nodes.contains { $0.coordinate == coordinate }
    }
}
