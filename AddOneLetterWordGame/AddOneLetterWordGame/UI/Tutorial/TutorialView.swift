import SwiftUI

struct TutorialView: View {
    @State private var step: Int = 0

    private var board: [[TileState?]] {
        switch step {
        case 0:
            return TutorialView.seedBoard
        case 1:
            return TutorialView.boardAfterPlacement
        default:
            return TutorialView.boardAfterWord
        }
    }

    private var placementCoordinate: BoardCoordinate? {
        step >= 1 ? BoardCoordinate(row: 3, column: 4) : nil
    }

    private var tracedNodes: [WordPath.Node] {
        step >= 2 ? TutorialView.traceNodes : []
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                BoardView(board: board, tracedNodes: tracedNodes, placementCoordinate: placementCoordinate) { _, _ in }
                    .allowsHitTesting(false)
                Text(description)
                    .multilineTextAlignment(.leading)
                invalidExamples
                Button(action: advance) {
                    Text(buttonTitle)
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.accentColor))
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
        .navigationTitle("Tutorial")
    }

    private var title: String {
        switch step {
        case 0: return "Welcome"
        case 1: return "Step 1: Place a Letter"
        case 2: return "Step 2: Trace a Word"
        default: return "Step 3: Submit & Score"
        }
    }

    private var description: String {
        switch step {
        case 0:
            return "Add one letter per turn. The new letter must touch existing tiles, and the word you trace must include it."
        case 1:
            return "Tap an empty square next to the word. A picker appears—choose the letter you want to add."
        case 2:
            return "Drag or tap tiles in order to spell a word. Each tile can be used once. Your new letter must be part of the path."
        default:
            return "Submit when the path spells a valid dictionary word. You'll earn points equal to the word's length and the turn passes."
        }
    }

    private var buttonTitle: String {
        step >= 3 ? "Start Playing" : "Next"
    }

    private var invalidExamples: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Avoid these common mistakes:")
                .font(.headline)
            Label("Word already used", systemImage: "xmark.circle")
                .font(.caption)
            Label("Tiles not touching", systemImage: "xmark.circle")
                .font(.caption)
            Label("Skipped the new letter", systemImage: "xmark.circle")
                .font(.caption)
            Label("Not in dictionary", systemImage: "xmark.circle")
                .font(.caption)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private func advance() {
        if step >= 3 {
            step = 0
        } else {
            step += 1
        }
    }

    private static let seedBoard: [[TileState?]] = {
        let size = 5
        var board = Array(repeating: Array(repeating: TileState?.none, count: size), count: size)
        let word = Array("READ")
        for (index, letter) in word.enumerated() {
            board[2][index + 1] = TileState(letter: Character(String(letter)), isSeed: true)
        }
        return board
    }()

    private static let boardAfterPlacement: [[TileState?]] = {
        var board = seedBoard
        board[3][4] = TileState(letter: "Y", isSeed: false)
        return board
    }()

    private static let boardAfterWord: [[TileState?]] = boardAfterPlacement

    private static let traceNodes: [WordPath.Node] = [
        WordPath.Node(coordinate: BoardCoordinate(row: 2, column: 1), letter: "R"),
        WordPath.Node(coordinate: BoardCoordinate(row: 2, column: 2), letter: "E"),
        WordPath.Node(coordinate: BoardCoordinate(row: 2, column: 3), letter: "A"),
        WordPath.Node(coordinate: BoardCoordinate(row: 2, column: 4), letter: "D"),
        WordPath.Node(coordinate: BoardCoordinate(row: 3, column: 4), letter: "Y")
    ]
}
