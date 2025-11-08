import Foundation

protocol AIPlayer {
    var difficulty: AIDifficulty { get }
    func chooseMove(using engine: GameEngine, settings: GameSettings) async -> WordCandidate?
}

final class EasyAIPlayer: AIPlayer {
    let difficulty: AIDifficulty = .easy
    func chooseMove(using engine: GameEngine, settings: GameSettings) async -> WordCandidate? {
        let candidates = await engine.availableMoves(limit: 25, heuristic: .balanced)
        let filtered = candidates.filter { $0.score <= 5 }
        if let candidate = filtered.randomElement() {
            return candidate
        }
        return candidates.randomElement()
    }
}

final class MediumAIPlayer: AIPlayer {
    let difficulty: AIDifficulty = .medium

    func chooseMove(using engine: GameEngine, settings: GameSettings) async -> WordCandidate? {
        let timeBudget = difficulty.timeBudget
        let start = Date()
        let candidates = await engine.availableMoves(limit: 30, heuristic: .balanced)
        guard !candidates.isEmpty else { return nil }
        var best: (WordCandidate, Double)?
        for candidate in candidates {
            let score = await evaluate(candidate: candidate, on: engine)
            if let currentBest = best {
                if score > currentBest.1 { best = (candidate, score) }
            } else {
                best = (candidate, score)
            }
            if Date().timeIntervalSince(start) > timeBudget * 0.8 {
                break
            }
        }
        return best?.0 ?? candidates.first
    }

    private func evaluate(candidate: WordCandidate, on engine: GameEngine) async -> Double {
        let board = await engine.board(afterApplying: candidate)
        let mobility = Double(await engine.mobility(on: board))
        let rarityScore = rarityWeight(for: candidate.move.letter)
        return Double(candidate.score) + mobility * 0.35 + rarityScore
    }

    private func rarityWeight(for letter: Character) -> Double {
        let vowels: Set<Character> = ["A", "E", "I", "O", "U"]
        if vowels.contains(letter) { return 0.2 }
        let rare: Set<Character> = ["J", "Q", "X", "Z"]
        return rare.contains(letter) ? 0.8 : 0.4
    }
}

final class HardAIPlayer: AIPlayer {
    let difficulty: AIDifficulty = .hard

    func chooseMove(using engine: GameEngine, settings: GameSettings) async -> WordCandidate? {
        let timeBudget = difficulty.timeBudget
        let start = Date()
        var bestCandidate: WordCandidate?
        var bestScore: Double = .leastNonzeroMagnitude

        let primaryCandidates = await engine.availableMoves(limit: 40, heuristic: .aggressive)
        guard !primaryCandidates.isEmpty else { return nil }

        for candidate in primaryCandidates {
            let score = await deepEvaluation(of: candidate, engine: engine, depth: 2)
            if score > bestScore {
                bestScore = score
                bestCandidate = candidate
            }
            if Date().timeIntervalSince(start) >= timeBudget {
                break
            }
        }

        return bestCandidate ?? primaryCandidates.max(by: { $0.score < $1.score })
    }

    private func deepEvaluation(of candidate: WordCandidate, engine: GameEngine, depth: Int) async -> Double {
        await engine.evaluate(candidate: candidate, depth: depth, heuristic: .aggressive)
    }
}
