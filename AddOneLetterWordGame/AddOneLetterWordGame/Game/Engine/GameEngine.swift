import Foundation

enum GameEngineError: LocalizedError {
    case seedWordLengthMismatch
    case seedWordNotInDictionary

    var errorDescription: String? {
        switch self {
        case .seedWordLengthMismatch:
            return "Seed word must match the selected board size."
        case .seedWordNotInDictionary:
            return "Seed word must be a valid dictionary entry."
        }
    }
}

enum WordSearchHeuristic {
    case aggressive
    case balanced
    case defensive
}

actor GameEngine {
    let settings: GameSettings
    private let dictionary: DictionaryService
    private let strictness: DictionaryStrictness

    private(set) var board: GameBoard
    private(set) var usedWords: Set<String>
    private(set) var players: [PlayerKind]
    private(set) var scores: [PlayerKind: Int]
    private(set) var currentPlayerIndex: Int
    private(set) var seedWord: String
    private(set) var startDate: Date
    private(set) var lastTurnDate: Date
    private var turnSnapshots: [GameSummary.TurnSnapshot]

    private let minimumWordLength = 3
    private var cachedLetterRanks: [Character]

    init(settings: GameSettings, seedWord: String, players: [PlayerKind], dictionary: DictionaryService) throws {
        guard settings.boardSize == seedWord.count else {
            throw GameEngineError.seedWordLengthMismatch
        }
        guard dictionary.contains(word: seedWord.lowercased(), strictness: .normal) else {
            throw GameEngineError.seedWordNotInDictionary
        }
        precondition(players.count == 2, "GameEngine currently supports exactly two players")

        self.settings = settings
        self.dictionary = dictionary
        self.strictness = settings.dictionaryStrictness
        self.board = GameBoard(size: settings.boardSize)
        self.players = players
        self.scores = Dictionary(uniqueKeysWithValues: players.map { ($0, 0) })
        self.currentPlayerIndex = 0
        self.seedWord = seedWord.uppercased()
        self.usedWords = Set([seedWord.lowercased()])
        self.startDate = Date()
        self.lastTurnDate = Date()
        self.turnSnapshots = []
        self.cachedLetterRanks = dictionary.orderedLetters()

        placeSeedWord()
    }

    func state() -> GameState {
        GameState(
            board: board,
            players: players,
            currentPlayerIndex: currentPlayerIndex,
            scores: scores,
            usedWords: usedWords,
            seedWord: seedWord
        )
    }

    func currentPlayer() -> PlayerKind { players[currentPlayerIndex] }

    func legalPlacements() -> [BoardCoordinate] {
        var placements = Set<BoardCoordinate>()
        for coordinate in board.filledCoordinates {
            for neighbor in coordinate.neighbors(within: board.size) where board[neighbor] == nil {
                placements.insert(neighbor)
            }
        }
        return placements.sorted { lhs, rhs in
            lhs.row == rhs.row ? lhs.column < rhs.column : lhs.row < rhs.row
        }
    }

    func canPlace(at coordinate: BoardCoordinate) -> Bool {
        guard coordinate.isValid(for: board.size), board[coordinate] == nil else { return false }
        return board.hasFilledNeighbor(coordinate)
    }

    func validate(move: GameMove) throws -> WordValidationResult {
        guard canPlace(at: move.coordinate) else {
            throw WordValidationError.invalidPlacement
        }
        return try validateWordPath(move.wordPath, for: move)
    }

    @discardableResult
    func apply(move: GameMove) throws -> GameTurnOutcome {
        let validation = try validate(move: move)
        var boardAfterPlacement = board
        let placedLetter = move.letter.uppercasedCharacter
        boardAfterPlacement[move.coordinate] = TileState(letter: placedLetter, isSeed: false, isNewlyPlaced: true)
        board = boardAfterPlacement
        usedWords.insert(validation.word.lowercased())

        let player = currentPlayer()
        scores[player, default: 0] += validation.score
        lastTurnDate = Date()

        let snapshot = GameSummary.TurnSnapshot(
            id: UUID(),
            index: turnSnapshots.count,
            player: player,
            word: validation.word,
            score: validation.score,
            boardSnapshot: boardAfterPlacement.toSnapshot(marking: move.coordinate),
            placedLetter: placedLetter,
            placement: move.coordinate,
            timestamp: lastTurnDate
        )
        turnSnapshots.append(snapshot)

        board.clearHighlights()
        advanceTurn()
        let gameOver = !hasAvailableMoves()
        let winner = gameOver ? determineWinner() : nil

        return GameTurnOutcome(
            move: move,
            validation: validation,
            updatedBoard: boardAfterPlacement,
            scoreAwarded: validation.score,
            isGameOver: gameOver,
            winningPlayer: winner
        )
    }

    func availableMoves(limit: Int, heuristic: WordSearchHeuristic = .balanced) -> [WordCandidate] {
        let analyzer = BoardAnalyzer(
            board: board,
            dictionary: dictionary,
            usedWords: usedWords,
            strictness: strictness,
            heuristic: heuristic,
            letterOrdering: letterOrder(for: heuristic)
        )
        return analyzer.availableMoves(limit: limit)
    }

    func hasAvailableMoves() -> Bool {
        !availableMoves(limit: 1).isEmpty
    }

    func summary(endDate: Date = Date()) -> GameSummary {
        GameSummary(
            id: UUID(),
            startDate: startDate,
            endDate: endDate,
            settings: settings,
            seedWord: seedWord,
            turns: turnSnapshots,
            wordsByPlayer: wordsPerPlayer(),
            scores: scores,
            winner: determineWinner(),
            longestWord: turnSnapshots.max(by: { $0.word.count < $1.word.count })?.word
        )
    }

    func board(afterApplying candidate: WordCandidate) -> GameBoard {
        var copy = board
        copy[candidate.move.coordinate] = TileState(letter: candidate.move.letter.uppercasedCharacter, isSeed: false, isNewlyPlaced: false)
        return copy
    }

    func mobility(on board: GameBoard) -> Int {
        var placements = Set<BoardCoordinate>()
        for coordinate in board.filledCoordinates {
            for neighbor in coordinate.neighbors(within: board.size) where board[neighbor] == nil {
                placements.insert(neighbor)
            }
        }
        return placements.count
    }

    func mobility(afterApplying candidate: WordCandidate) -> Int {
        mobility(on: board(afterApplying: candidate))
    }

    func analyzer(for board: GameBoard, including additionalWords: Set<String> = [], heuristic: WordSearchHeuristic = .balanced) -> BoardAnalyzer {
        BoardAnalyzer(
            board: board,
            dictionary: dictionary,
            usedWords: usedWords.union(additionalWords),
            strictness: strictness,
            heuristic: heuristic,
            letterOrdering: letterOrder(for: heuristic)
        )
    }

    private func placeSeedWord() {
    func evaluate(candidate: WordCandidate, depth: Int, heuristic: WordSearchHeuristic) -> Double {
        var value = Double(candidate.score) * 2.0
        let boardAfterMove = board(afterApplying: candidate)
        let mobilityScore = Double(mobility(on: boardAfterMove))
        value += mobilityScore * 0.5

        let rareLetters: Set<Character> = ["J", "Q", "X", "Z"]
        if rareLetters.contains(candidate.move.letter) {
            value += 0.75
        }

        guard depth > 0 else { return value }
        let analyzer = analyzer(for: boardAfterMove, including: [candidate.word.lowercased()], heuristic: heuristic)
        let opponentMoves = analyzer.availableMoves(limit: 5)
        if let bestOpponent = opponentMoves.first {
            value -= Double(bestOpponent.score) * 1.3
        }
        return value
    }

        let startColumn = (board.size - seedWord.count) / 2
        let seedRow = board.size / 2
        for (index, char) in seedWord.enumerated() {
            let coordinate = BoardCoordinate(row: seedRow, column: startColumn + index)
            board[coordinate] = TileState(letter: char, isSeed: true, isNewlyPlaced: false)
        }
    }

    private func advanceTurn() {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
    }

    private func determineWinner() -> PlayerKind? {
        guard let highest = scores.max(by: { $0.value < $1.value }) else { return nil }
        let winners = scores.filter { $0.value == highest.value }
        return winners.count == 1 ? winners.keys.first : nil
    }

    private func wordsPerPlayer() -> [PlayerKind: [String]] {
        turnSnapshots.reduce(into: [PlayerKind: [String]]()) { partialResult, snapshot in
            partialResult[snapshot.player, default: []].append(snapshot.word)
        }
    }

    private func validateWordPath(_ path: WordPath, for move: GameMove) throws -> WordValidationResult {
        guard path.nodes.count >= minimumWordLength else {
            throw WordValidationError.wordTooShort
        }
        guard path.contains(move.coordinate) else {
            throw WordValidationError.missingNewLetter
        }

        var visited: Set<BoardCoordinate> = []
        var wordBuilder = ""
        let placedLetter = move.letter.uppercasedCharacter

        for (index, node) in path.nodes.enumerated() {
            let coordinate = node.coordinate
            guard coordinate.isValid(for: board.size) else {
                throw WordValidationError.disconnectedPath
            }
            guard !visited.contains(coordinate) else {
                throw WordValidationError.reusedTile
            }
            if index > 0 {
                let previous = path.nodes[index - 1].coordinate
                guard previous.neighbors(within: board.size).contains(coordinate) else {
                    throw WordValidationError.disconnectedPath
                }
            }

            let expectedLetter: Character
            if coordinate == move.coordinate {
                expectedLetter = placedLetter
            } else if let tile = board[coordinate] {
                expectedLetter = tile.letter
            } else {
                throw WordValidationError.disconnectedPath
            }

            let comparedLetter = node.letter.uppercasedCharacter
            guard expectedLetter == comparedLetter else {
                throw WordValidationError.disconnectedPath
            }

            visited.insert(coordinate)
            wordBuilder.append(expectedLetter.lowercasedString)
        }

        guard !usedWords.contains(wordBuilder) else {
            throw WordValidationError.wordAlreadyUsed
        }
        guard dictionary.contains(word: wordBuilder, strictness: strictness) else {
            throw WordValidationError.missingDictionaryEntry
        }

        return WordValidationResult(path: path, word: wordBuilder.uppercased(), score: wordBuilder.count)
    }

    private func letterOrder(for heuristic: WordSearchHeuristic) -> [Character] {
        switch heuristic {
        case .aggressive:
            return cachedLetterRanks
        case .balanced:
            return cachedLetterRanks
        case .defensive:
            return cachedLetterRanks.reversed()
        }
    }
}
