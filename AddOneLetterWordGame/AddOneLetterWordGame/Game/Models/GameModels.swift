import Foundation

enum GameMode: String, Codable, CaseIterable, Identifiable {
    case versusAI
    case passAndPlay

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .versusAI:
            return "Play vs Computer"
        case .passAndPlay:
            return "Pass & Play"
        }
    }
}

enum AIDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy:
            return "Easy"
        case .medium:
            return "Medium"
        case .hard:
            return "Hard"
        }
    }

    var timeBudget: TimeInterval {
        switch self {
        case .easy:
            return 0.25
        case .medium:
            return 0.45
        case .hard:
            return 0.95
        }
    }
}

enum DictionaryStrictness: String, Codable, CaseIterable, Identifiable {
    case normal
    case strict

    var id: String { rawValue }

    var minimumFrequency: Double {
        switch self {
        case .normal:
            return 2.75
        case .strict:
            return 3.4
        }
    }

    var displayName: String {
        switch self {
        case .normal:
            return "Normal"
        case .strict:
            return "Strict"
        }
    }
}

struct GameSettings: Equatable, Codable {
    var boardSize: Int
    var mode: GameMode
    var aiDifficulty: AIDifficulty
    var dictionaryStrictness: DictionaryStrictness
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var hintsEnabled: Bool

    static let `default` = GameSettings(
        boardSize: 5,
        mode: .versusAI,
        aiDifficulty: .medium,
        dictionaryStrictness: .normal,
        soundEnabled: true,
        hapticsEnabled: true,
        hintsEnabled: false
    )

    var seedLengthRange: ClosedRange<Int> { 4...7 }
}

enum PlayerKind: Equatable, Identifiable, Hashable {
    case human(name: String)
    case computer(name: String, difficulty: AIDifficulty)

    var id: String {
        switch self {
        case let .human(name):
            return "human_\(name)"
        case let .computer(name, difficulty):
            return "computer_\(name)_\(difficulty.rawValue)"
        }
    }

    var displayName: String {
        switch self {
        case let .human(name):
            return name
        case let .computer(name, _):
            return name
        }
    }

    var isComputer: Bool {
        switch self {
        case .human:
            return false
        case .computer:
            return true
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case let .human(name):
            hasher.combine("human")
            hasher.combine(name)
        case let .computer(name, difficulty):
            hasher.combine("computer")
            hasher.combine(name)
            hasher.combine(difficulty)
        }
    }
}

struct PlayerScore: Equatable {
    var player: PlayerKind
    var score: Int

    mutating func add(points: Int) {
        score += points
    }
}

struct GameSummary: Identifiable, Equatable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let settings: GameSettings
    let seedWord: String
    let turns: [TurnSnapshot]
    let wordsByPlayer: [PlayerKind: [String]]
    let scores: [PlayerKind: Int]
    let winner: PlayerKind?
    let longestWord: String?

    struct TurnSnapshot: Identifiable, Equatable {
        let id: UUID
        let index: Int
        let player: PlayerKind
        let word: String
        let score: Int
        let boardSnapshot: [[TileState?]]
        let placedLetter: Character
        let placement: BoardCoordinate
        let timestamp: Date
    }
}
