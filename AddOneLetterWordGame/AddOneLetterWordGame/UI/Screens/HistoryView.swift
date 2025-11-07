import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [SortDescriptor(\.date, order: .reverse)])
    private var matches: FetchedResults<MatchRecord>
    @State private var searchText: String = ""

    private var filteredMatches: [MatchRecord] {
        matches.filter { match in
            guard !searchText.isEmpty else { return true }
            return match.seedWord.localizedCaseInsensitiveContains(searchText) ||
                (match.longestWord?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredMatches, id: \.self) { match in
                    NavigationLink(destination: MatchDetailView(match: match)) {
                        HistoryRow(match: match)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("History")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .overlay(
                Group {
                    if matches.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "rectangle.on.rectangle.slash")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No matches yet").font(.headline)
                            Text("Play a game to build history.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            )
        }
    }
}

private struct HistoryRow: View {
    let match: MatchRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(match.seedWord.uppercased())
                    .font(.headline)
                Spacer()
                Text(match.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 12) {
                Label("\(match.mode.capitalized)", systemImage: "person.2")
                    .font(.caption)
                if let difficulty = match.aiDifficulty {
                    Label(difficulty.capitalized, systemImage: "brain.head.profile")
                        .font(.caption2)
                }
                Label("Board \(match.boardSize)×\(match.boardSize)", systemImage: "square.grid.3x3")
                    .font(.caption2)
            }
            HStack {
                Text("Score: \(match.playerOneScore) - \(match.playerTwoScore)")
                Spacer()
                if let longest = match.longestWord {
                    Text("Longest \(longest.uppercased())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .font(.subheadline)
        }
        .padding(.vertical, 6)
    }
}

private struct MatchDetailView: View {
    let match: MatchRecord
    @State private var selectedTurnIndex: Int = 0

    private var summary: GameSummary? {
        MatchRepository(container: PersistenceController.shared.container).makeSummary(from: match)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summarySection
                replaySection
                wordsSection
            }
            .padding()
        }
        .navigationTitle("Match Summary")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summarySection: some View {
        Group {
            if let summary {
                VStack(alignment: .leading, spacing: 8) {
                    Text(summary.seedWord.uppercased())
                        .font(.title2.weight(.semibold))
                    Text(summary.startDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Divider()
                    HStack {
                        Text("Mode")
                        Spacer()
                        Text(summary.settings.mode.displayName)
                    }
                    HStack {
                        Text("Board")
                        Spacer()
                        Text("\(summary.settings.boardSize)×\(summary.settings.boardSize)")
                    }
                    HStack {
                        Text("Turns")
                        Spacer()
                        Text("\(summary.turns.count)")
                    }
                    if let winner = summary.winner {
                        HStack {
                            Text("Winner")
                            Spacer()
                            Text(winner.displayName)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
    }

    private var replaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Replay")
                .font(.headline)
            if match.sortedTurns.isEmpty {
                Text("No turns recorded")
                    .foregroundColor(.secondary)
            } else {
                TabView(selection: $selectedTurnIndex) {
                    ForEach(Array(match.sortedTurns.enumerated()), id: \.offset) { index, turn in
                        BoardSnapshotView(board: decodeBoard(from: turn.boardSnapshot))
                            .padding(.vertical)
                            .tag(index)
                            .overlay(alignment: .bottom) {
                                VStack(spacing: 4) {
                                    Text("Turn \(index + 1): \(turn.player)")
                                        .font(.caption)
                                    Text("Word: \(turn.word.uppercased()) (+\(turn.score))")
                                        .font(.caption2)
                                }
                                .padding(8)
                                .background(Capsule().fill(Color.black.opacity(0.5)))
                                .foregroundColor(.white)
                                .padding(.bottom, 12)
                            }
                    }
                }
                .frame(height: 320)
                .tabViewStyle(.page)
            }
        }
    }

    private var wordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Words")
                .font(.headline)
            ForEach(Array(match.sortedWords.enumerated()), id: \.offset) { _, wordRecord in
                HStack {
                    Text(wordRecord.player)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(wordRecord.text.uppercased())
                    Spacer()
                    Text("+\(wordRecord.score)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func decodeBoard(from snapshot: String?) -> [[TileState?]] {
        guard let snapshot, let data = Data(base64Encoded: snapshot) else { return [] }
        return (try? JSONDecoder().decode([[TileState?]].self, from: data)) ?? []
    }
}

private struct BoardSnapshotView: View {
    let board: [[TileState?]]

    var body: some View {
        if board.isEmpty {
            Text("Snapshot unavailable")
                .foregroundColor(.secondary)
        } else {
            BoardView(board: board, tracedNodes: [], placementCoordinate: nil) { _, _ in }
                .allowsHitTesting(false)
        }
    }
}
