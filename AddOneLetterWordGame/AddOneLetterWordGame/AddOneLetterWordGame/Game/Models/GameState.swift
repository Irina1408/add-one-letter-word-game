import Foundation

struct GameState: Equatable {
    let board: GameBoard
    let players: [PlayerKind]
    let currentPlayerIndex: Int
    let scores: [PlayerKind: Int]
    let usedWords: Set<String>
    let seedWord: String

    var currentPlayer: PlayerKind { players[currentPlayerIndex] }

    func score(for player: PlayerKind) -> Int {
        scores[player] ?? 0
    }
}
