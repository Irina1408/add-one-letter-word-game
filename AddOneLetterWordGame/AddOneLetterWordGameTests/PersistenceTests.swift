import XCTest
import CoreData
@testable import AddOneLetterWordGame

final class PersistenceTests: XCTestCase {
    func testRecordAndFetchMatch() async throws {
        let controller = PersistenceController(inMemory: true)
        let repository = MatchRepository(container: controller.container)

        let boardSize = 4
        let boardSnapshot: [[TileState?]] = [
            [nil, nil, nil, nil],
            [TileState(letter: "B", isSeed: false), nil, nil, nil],
            [TileState(letter: "R", isSeed: true), TileState(letter: "E", isSeed: true), TileState(letter: "A", isSeed: true), TileState(letter: "D", isSeed: true)],
            [nil, nil, nil, nil]
        ]

        let turn = GameSummary.TurnSnapshot(
            id: UUID(),
            index: 0,
            player: .human(name: "Player 1"),
            word: "BREAD",
            score: 5,
            boardSnapshot: boardSnapshot,
            placedLetter: "B",
            placement: BoardCoordinate(row: 1, column: 0),
            timestamp: Date()
        )

        let summary = GameSummary(
            id: UUID(),
            startDate: Date(),
            endDate: Date().addingTimeInterval(60),
            settings: GameSettings(boardSize: boardSize, mode: .versusAI, aiDifficulty: .easy, dictionaryStrictness: .normal, soundEnabled: true, hapticsEnabled: true, hintsEnabled: false),
            seedWord: "READ",
            turns: [turn],
            wordsByPlayer: [.human(name: "Player 1"): ["BREAD"]],
            scores: [.human(name: "Player 1"): 5, .computer(name: "Bot", difficulty: .easy): 3],
            winner: .human(name: "Player 1"),
            longestWord: "BREAD"
        )

        try await repository.record(summary: summary)
        let history = try repository.fetchHistory()
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.seedWord.uppercased(), "READ")
    }
}
