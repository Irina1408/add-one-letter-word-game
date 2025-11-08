import XCTest
@testable import AddOneLetterWordGame

final class GameEngineTests: XCTestCase {
    private var dictionary: DictionaryService!

    override func setUp() async throws {
        dictionary = DictionaryService()
        await dictionary.loadIfNeeded(from: resourceBundle)
    }

    func testSeedWordPlacementAndLegalMoves() async throws {
        let settings = GameSettings(boardSize: 4, mode: .versusAI, aiDifficulty: .easy, dictionaryStrictness: .normal, soundEnabled: true, hapticsEnabled: true, hintsEnabled: false)
        let engine = try GameEngine(settings: settings, seedWord: "read", players: [.human(name: "Tester"), .computer(name: "AI", difficulty: .easy)], dictionary: dictionary)

        let placements = await engine.legalPlacements()
        XCTAssertFalse(placements.isEmpty)
        XCTAssertTrue(placements.allSatisfy { $0.isValid(for: settings.boardSize) })
    }

    func testApplyingMoveScoresCorrectly() async throws {
        var settings = GameSettings.default
        settings.boardSize = 4
        let engine = try GameEngine(settings: settings, seedWord: "read", players: [.human(name: "Tester"), .computer(name: "AI", difficulty: .easy)], dictionary: dictionary)

        let coordinate = BoardCoordinate(row: 1, column: 0)
        let path = WordPath(nodes: [
            WordPath.Node(coordinate: BoardCoordinate(row: 1, column: 0), letter: "B"),
            WordPath.Node(coordinate: BoardCoordinate(row: 2, column: 0), letter: "R"),
            WordPath.Node(coordinate: BoardCoordinate(row: 2, column: 1), letter: "E"),
            WordPath.Node(coordinate: BoardCoordinate(row: 2, column: 2), letter: "A"),
            WordPath.Node(coordinate: BoardCoordinate(row: 2, column: 3), letter: "D")
        ])
        let move = GameMove(coordinate: coordinate, letter: "B", wordPath: path)

        let outcome = try await engine.apply(move: move)
        XCTAssertEqual(outcome.scoreAwarded, 5)
        let state = await engine.state()
        XCTAssertEqual(state.score(for: state.players[0]), 5)
    }

    func testRejectsDuplicateWord() async throws {
        let settings = GameSettings(boardSize: 4, mode: .versusAI, aiDifficulty: .easy, dictionaryStrictness: .normal, soundEnabled: true, hapticsEnabled: true, hintsEnabled: false)
        let engine = try GameEngine(settings: settings, seedWord: "read", players: [.human(name: "Tester"), .computer(name: "AI", difficulty: .easy)], dictionary: dictionary)

        let firstCoordinate = BoardCoordinate(row: 1, column: 0)
        let firstPath = WordPath(nodes: [
            WordPath.Node(coordinate: BoardCoordinate(row: 1, column: 0), letter: "B"),
            WordPath.Node(coordinate: BoardCoordinate(row: 2, column: 0), letter: "R"),
            WordPath.Node(coordinate: BoardCoordinate(row: 2, column: 1), letter: "E"),
            WordPath.Node(coordinate: BoardCoordinate(row: 2, column: 2), letter: "A"),
            WordPath.Node(coordinate: BoardCoordinate(row: 2, column: 3), letter: "D")
        ])
        let firstMove = GameMove(coordinate: firstCoordinate, letter: "B", wordPath: firstPath)
        _ = try await engine.apply(move: firstMove)

        let secondCoordinate = BoardCoordinate(row: 3, column: 0)
        let secondPath = WordPath.Node.makePath(for: [
            (BoardCoordinate(row: 3, column: 0), "B"),
            (BoardCoordinate(row: 2, column: 0), "R"),
            (BoardCoordinate(row: 2, column: 1), "E"),
            (BoardCoordinate(row: 2, column: 2), "A"),
            (BoardCoordinate(row: 2, column: 3), "D")
        ])
        let secondMove = GameMove(coordinate: secondCoordinate, letter: "B", wordPath: WordPath(nodes: secondPath))

        await XCTAssertThrowsErrorAsync(try await engine.apply(move: secondMove)) { error in
            XCTAssertEqual(error as? WordValidationError, .wordAlreadyUsed)
        }
    }

    private var resourceBundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: GameEngineTests.self)
        #endif
    }
}

private extension WordPath.Node {
    static func makePath(for pairs: [(BoardCoordinate, Character)]) -> [WordPath.Node] {
        pairs.map { WordPath.Node(coordinate: $0.0, letter: $0.1) }
    }
}

extension XCTestCase {
    func XCTAssertThrowsErrorAsync<T>(_ expression: @autoclosure () async throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line, _ errorHandler: (Error) -> Void = { _ in }) async {
        do {
            _ = try await expression()
            XCTFail(message(), file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }
}
