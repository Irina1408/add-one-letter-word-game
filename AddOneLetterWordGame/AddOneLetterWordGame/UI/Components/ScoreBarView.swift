import SwiftUI

struct ScoreBarView: View {
    let scores: [PlayerKind: Int]
    let currentPlayer: PlayerKind

    var body: some View {
        HStack(spacing: 12) {
            ForEach(sortedPlayers, id: \.id) { player in
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(scores[player] ?? 0)")
                        .font(.title2.weight(.semibold))
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(cardBackground(for: player))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderColor(for: player), lineWidth: 1.5)
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(player.displayName) has \(scores[player] ?? 0) points")
            }
        }
    }

    private var sortedPlayers: [PlayerKind] {
        scores.keys.sorted { $0.id < $1.id }
    }

    private func cardBackground(for player: PlayerKind) -> some View {
        Group {
            if player.id == currentPlayer.id {
                Color.accentColor.opacity(0.2)
            } else {
                Color(.secondarySystemBackground)
            }
        }
    }

    private func borderColor(for player: PlayerKind) -> Color {
        player.id == currentPlayer.id ? Color.accentColor : Color.primary.opacity(0.1)
    }
}

struct ScoreBarView_Previews: PreviewProvider {
    static var previews: some View {
        let scores: [PlayerKind: Int] = [.human(name: "You"): 18, .computer(name: "Lexi", difficulty: .medium): 14]
        ScoreBarView(scores: scores, currentPlayer: .human(name: "You"))
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
