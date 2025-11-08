import XCTest
@testable import AddOneLetterWordGame

final class AITests: XCTestCase {
    private var dictionary: DictionaryService!

    override func setUp() async throws {
        dictionary = DictionaryService()
        await dictionary.loadIfNeeded(from: resourceBundle)
    }

    func testEasyAIFindsMove() async throws {
        try await assertAIMove(for: EasyAIPlayer())
    }

    func testMediumAIFindsMove() async throws {
        try await assertAIMove(for: MediumAIPlayer())
    }

    func testHardAIFindsMoveWithinBudget() async throws {
        try await assertAIMove(for: HardAIPlayer())
    }

    private func assertAIMove(for player: AIPlayer) async throws {
        let settings = GameSettings(boardSize: 4, mode: .versusAI, aiDifficulty: player.difficulty, dictionaryStrictness: .normal, soundEnabled: true, hapticsEnabled: true, hintsEnabled: false)
        let engine = try GameEngine(settings: settings, seedWord: "read", players: [.human(name: "Tester"), .computer(name: "Bot", difficulty: player.difficulty)], dictionary: dictionary)
        let start = Date()
        let candidate = await player.chooseMove(using: engine, settings: settings)
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertNotNil(candidate)
        XCTAssertLessThan(elapsed, player.difficulty.timeBudget + 0.5)
    }

    private var resourceBundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: AITests.self)
        #endif
    }
}
