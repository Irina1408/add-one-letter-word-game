import Foundation

struct GameMove: Equatable {
    let coordinate: BoardCoordinate
    let letter: Character
    let wordPath: WordPath
}

enum WordValidationError: Error, Equatable, LocalizedError {
    case wordAlreadyUsed
    case wordTooShort
    case missingDictionaryEntry
    case missingNewLetter
    case reusedTile
    case disconnectedPath
    case invalidPlacement

    var errorDescription: String? {
        switch self {
        case .wordAlreadyUsed:
            return "That word was already played. Try something new!"
        case .wordTooShort:
            return "Words must be at least three letters."
        case .missingDictionaryEntry:
            return "We couldn't find that word in the dictionary."
        case .missingNewLetter:
            return "The new letter must be part of the word you trace."
        case .reusedTile:
            return "Each tile can only be used once per word."
        case .disconnectedPath:
            return "Letters must touch horizontally or vertically."
        case .invalidPlacement:
            return "Place letters next to existing tiles."
        }
    }
}

struct WordValidationResult: Equatable {
    let path: WordPath
    let word: String
    let score: Int
}

struct GameTurnOutcome: Equatable {
    let move: GameMove
    let validation: WordValidationResult
    let updatedBoard: GameBoard
    let scoreAwarded: Int
    let isGameOver: Bool
    let winningPlayer: PlayerKind?
}

struct WordCandidate: Equatable {
    let move: GameMove
    let score: Int
    let word: String
}
