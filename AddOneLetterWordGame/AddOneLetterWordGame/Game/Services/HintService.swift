import Foundation

struct HintSuggestion: Identifiable {
    let id = UUID()
    let coordinate: BoardCoordinate
    let letter: Character
    let word: String
    let score: Int

    var message: String {
        "There's a \(word.count)-letter word starting near R\(coordinate.row + 1)C\(coordinate.column + 1)."
    }
}

final class HintService {
    func makeHint(from engine: GameEngine, heuristic: WordSearchHeuristic = .balanced) async -> HintSuggestion? {
        let candidates = await engine.availableMoves(limit: 3, heuristic: heuristic)
        return candidates.first.map { candidate in
            HintSuggestion(
                coordinate: candidate.move.coordinate,
                letter: candidate.move.letter,
                word: candidate.word,
                score: candidate.score
            )
        }
    }
}
