import CoreData
import Foundation

final class MatchRepository {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func record(summary: GameSummary) async throws {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        try await context.perform {
            let match = MatchRecord(context: context)
            match.id = summary.id
            match.date = summary.startDate
            match.duration = summary.endDate.timeIntervalSince(summary.startDate)
            match.boardSize = Int16(summary.settings.boardSize)
            match.mode = summary.settings.mode.rawValue
            match.aiDifficulty = summary.settings.mode == .versusAI ? summary.settings.aiDifficulty.rawValue : nil
            match.seedWord = summary.seedWord
            match.turnCount = Int32(summary.turns.count)
            let sortedPlayers = summary.scores.keys.sorted { $0.id < $1.id }
            if let first = sortedPlayers.first {
                match.playerOneScore = Int32(summary.scores[first] ?? 0)
            }
            if sortedPlayers.count > 1 {
                let second = sortedPlayers[1]
                match.playerTwoScore = Int32(summary.scores[second] ?? 0)
            }
            match.winner = summary.winner?.id
            match.longestWord = summary.longestWord

            for turn in summary.turns {
                let turnRecord = TurnRecord(context: context)
                turnRecord.index = Int32(turn.index)
                turnRecord.player = turn.player.id
                turnRecord.word = turn.word
                turnRecord.score = Int16(turn.score)
                turnRecord.timestamp = turn.timestamp
                turnRecord.placementRow = Int16(turn.placement.row)
                turnRecord.placementColumn = Int16(turn.placement.column)
                turnRecord.placedLetter = String(turn.placedLetter)
                if let encoded = try? encodeBoardSnapshot(turn.boardSnapshot) {
                    turnRecord.boardSnapshot = encoded
                }
                match.addToTurns(turnRecord)
            }

            for (player, words) in summary.wordsByPlayer {
                for (index, word) in words.enumerated() {
                    let wordRecord = WordRecord(context: context)
                    wordRecord.player = player.id
                    wordRecord.text = word
                    wordRecord.score = Int16(word.count)
                    wordRecord.turnIndex = Int32(index)
                    match.addToWords(wordRecord)
                }
            }

            try context.save()
        }
    }

    func fetchHistory(limit: Int = 50) throws -> [MatchRecord] {
        let request: NSFetchRequest<MatchRecord> = MatchRecord.fetchRequest()
        request.fetchLimit = limit
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MatchRecord.date, ascending: false)]
        return try container.viewContext.fetch(request)
    }

    func makeSummary(from record: MatchRecord) -> GameSummary? {
        guard let endDate = Calendar.current.date(byAdding: .second, value: Int(record.duration), to: record.date) else { return nil }
        let settings = GameSettings(
            boardSize: Int(record.boardSize),
            mode: GameMode(rawValue: record.mode) ?? .versusAI,
            aiDifficulty: AIDifficulty(rawValue: record.aiDifficulty ?? AIDifficulty.medium.rawValue) ?? .medium,
            dictionaryStrictness: .normal,
            soundEnabled: true,
            hapticsEnabled: true,
            hintsEnabled: false
        )

        var wordsByPlayer: [PlayerKind: [String]] = [:]
        var playersSet = Set<PlayerKind>()
        for wordRecord in record.sortedWords {
            let player = playerKind(for: wordRecord.player)
            playersSet.insert(player)
            wordsByPlayer[player, default: []].append(wordRecord.text)
        }
        if playersSet.isEmpty {
            playersSet.insert(.human(name: "Player 1"))
            if record.mode == GameMode.versusAI.rawValue {
                let difficulty = AIDifficulty(rawValue: record.aiDifficulty ?? AIDifficulty.medium.rawValue) ?? .medium
                playersSet.insert(.computer(name: "Lexi", difficulty: difficulty))
            } else {
                playersSet.insert(.human(name: "Player 2"))
            }
        }

        let turns = record.sortedTurns.enumerated().compactMap { index, turn -> GameSummary.TurnSnapshot? in
            guard let placedLetter = turn.placedLetter.first else { return nil }
            let board = (try? decodeBoardSnapshot(turn.boardSnapshot)) ?? []
            return GameSummary.TurnSnapshot(
                id: UUID(),
                index: index,
                player: playerKind(for: turn.player),
                word: turn.word,
                score: Int(turn.score),
                boardSnapshot: board,
                placedLetter: placedLetter,
                placement: BoardCoordinate(row: Int(turn.placementRow), column: Int(turn.placementColumn)),
                timestamp: turn.timestamp
            )
        }

        var scores: [PlayerKind: Int] = [:]
        let sortedPlayers = playersSet.sorted { $0.id < $1.id }
        if let first = sortedPlayers.first {
            scores[first] = Int(record.playerOneScore)
        }
        if sortedPlayers.count > 1 {
            scores[sortedPlayers[1]] = Int(record.playerTwoScore)
        }

        let winner = record.winner.map(playerKind)

        return GameSummary(
            id: record.id,
            startDate: record.date,
            endDate: endDate,
            settings: settings,
            seedWord: record.seedWord,
            turns: turns,
            wordsByPlayer: wordsByPlayer,
            scores: scores,
            winner: winner,
            longestWord: record.longestWord
        )
    }

    private func encodeBoardSnapshot(_ snapshot: [[TileState?]]) throws -> String {
        let data = try JSONEncoder().encode(snapshot)
        return data.base64EncodedString()
    }

    private func decodeBoardSnapshot(_ string: String?) throws -> [[TileState?]] {
        guard let string, let data = Data(base64Encoded: string) else { return [] }
        return try JSONDecoder().decode([[TileState?]].self, from: data)
    }

    private func playerKind(for identifier: String) -> PlayerKind {
        if identifier.starts(with: "computer_") {
            let components = identifier.split(separator: "_")
            if components.count >= 3 {
                let name = components[1...components.count-2].joined(separator: " ")
                let difficultyRaw = String(components.last!)
                let difficulty = AIDifficulty(rawValue: difficultyRaw) ?? .medium
                return .computer(name: name, difficulty: difficulty)
            }
        }
        let name = identifier.replacingOccurrences(of: "human_", with: "")
        return .human(name: name.isEmpty ? "Player" : name)
    }
}

