import Foundation

struct BoardAnalyzer {
    let board: GameBoard
    let dictionary: DictionaryService
    let usedWords: Set<String>
    let strictness: DictionaryStrictness
    let heuristic: WordSearchHeuristic
    let letterOrdering: [Character]

    func availableMoves(limit: Int) -> [WordCandidate] {
        guard limit > 0 else { return [] }
        var candidates: [WordCandidate] = []
        var seen = Set<String>()
        let placements = legalPlacements()

        for coordinate in placements {
            for letter in letterOrdering {
                let generated = generateCandidates(for: coordinate, letter: letter, limit: max(4, limit * 2))
                for candidate in generated {
                    if seen.insert(candidate.word.lowercased()).inserted {
                        candidates.append(candidate)
                    }
                    if candidates.count >= limit { break }
                }
                if candidates.count >= limit { break }
            }
            if candidates.count >= limit { break }
        }

        return candidates
            .sorted { lhs, rhs in
                if lhs.score == rhs.score { return lhs.word < rhs.word }
                return lhs.score > rhs.score
            }
            .prefix(limit)
            .map { $0 }
    }

    private func legalPlacements() -> [BoardCoordinate] {
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

    private func generateCandidates(for coordinate: BoardCoordinate, letter: Character, limit: Int) -> [WordCandidate] {
        guard limit > 0 else { return [] }
        var tempBoard = board
        tempBoard[coordinate] = TileState(letter: letter.uppercasedCharacter, isSeed: false, isNewlyPlaced: false)
        return searchWords(on: tempBoard, placing: letter, at: coordinate, limit: limit)
    }

    private func searchWords(on board: GameBoard, placing letter: Character, at newLetterCoordinate: BoardCoordinate, limit: Int) -> [WordCandidate] {
        var candidates: [WordCandidate] = []
        var seen = Set<String>()
        let maxDepth: Int
        switch heuristic {
        case .aggressive: maxDepth = 12
        case .balanced: maxDepth = 10
        case .defensive: maxDepth = 8
        }
        let lowercaseTiles: [BoardCoordinate: Character] = board.filledCoordinates.reduce(into: [:]) { partial, coordinate in
            if let tile = board[coordinate]?.letter {
                partial[coordinate] = tile.lowercasedCharacter
            }
        }
        let coordinates = lowercaseTiles.keys.sorted { lhs, rhs in
            lhs == newLetterCoordinate ? true : (rhs == newLetterCoordinate ? false : (lhs.row == rhs.row ? lhs.column < rhs.column : lhs.row < rhs.row))
        }

        func dfs(path: [BoardCoordinate], letters: [Character], usedNewLetter: Bool) {
            guard path.count <= maxDepth else { return }
            let word = String(letters)

            if letters.count >= 3 && usedNewLetter {
                if dictionary.contains(word: word, strictness: strictness) && !usedWords.contains(word) {
                    if seen.insert(word).inserted {
                        let nodes = zip(path, letters).map { WordPath.Node(coordinate: $0.0, letter: $0.1.uppercasedCharacter) }
                        let move = GameMove(coordinate: newLetterCoordinate, letter: letter.uppercasedCharacter, wordPath: WordPath(nodes: nodes))
                        candidates.append(WordCandidate(move: move, score: letters.count, word: word.uppercased()))
                        if candidates.count >= limit { return }
                    }
                }
            }

            guard dictionary.hasPrefix(word) else { return }
            guard let last = path.last else { return }
            for neighbor in last.neighbors(within: board.size) where board[neighbor] != nil {
                if path.contains(neighbor) { continue }
                guard let nextLetter = lowercaseTiles[neighbor] else { continue }
                dfs(path: path + [neighbor], letters: letters + [nextLetter], usedNewLetter: usedNewLetter || neighbor == newLetterCoordinate)
                if candidates.count >= limit { return }
            }
        }

        for coordinate in coordinates {
            guard let startLetter = lowercaseTiles[coordinate] else { continue }
            dfs(path: [coordinate], letters: [startLetter], usedNewLetter: coordinate == newLetterCoordinate)
            if candidates.count >= limit { break }
        }

        return candidates
    }
}
