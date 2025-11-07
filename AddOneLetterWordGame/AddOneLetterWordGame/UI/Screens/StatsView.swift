import SwiftUI
import CoreData

struct StatsView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\.date, order: .reverse)])
    private var matches: FetchedResults<MatchRecord>

    private var wordRecords: [WordRecord] {
        matches.flatMap { ($0.words as? Set<WordRecord>) ?? [] }
    }

    private var wins: Int {
        matches.filter { $0.winner?.hasPrefix("human_") == true }.count
    }

    private var losses: Int {
        matches.filter { $0.mode == GameMode.versusAI.rawValue && $0.winner?.hasPrefix("computer_") == true }.count
    }

    private var averageWordLength: Double {
        let lengths = wordRecords.map { Double($0.text.count) }
        guard !lengths.isEmpty else { return 0 }
        return lengths.reduce(0, +) / Double(lengths.count)
    }

    private var longestWord: String {
        wordRecords.max(by: { $0.text.count < $1.text.count })?.text.uppercased() ?? "—"
    }

    private var mostUsedLetter: Character? {
        var tally: [Character: Int] = [:]
        for record in wordRecords {
            for letter in record.text.uppercased() {
                tally[letter, default: 0] += 1
            }
        }
        return tally.max(by: { $0.value < $1.value })?.key
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        StatCard(title: "Games", value: "\(matches.count)", subtitle: "Completed matches")
                        StatCard(title: "Wins", value: "\(wins)", subtitle: "Versus AI")
                        StatCard(title: "Losses", value: "\(losses)", subtitle: "Versus AI")
                    }
                    .frame(maxWidth: .infinity)

                    HStack(spacing: 16) {
                        StatCard(title: "Avg Word", value: averageWordLength.isNaN ? "—" : String(format: "%.1f", averageWordLength), subtitle: "Letters per word")
                        StatCard(title: "Longest", value: longestWord, subtitle: "Top word")
                        StatCard(title: "Popular", value: mostUsedLetter.map(String.init) ?? "—", subtitle: "Most-used letter")
                    }

                    if matches.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No stats yet")
                                .font(.headline)
                            Text("Complete games to see your progress.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    }
                }
                .padding()
            }
            .navigationTitle("Stats")
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2.weight(.bold))
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }
}
