import SwiftUI

struct BoardView: View {
    let board: [[TileState?]]
    let tracedNodes: [WordPath.Node]
    let placementCoordinate: BoardCoordinate?
    let onTap: (BoardCoordinate, TileState?) -> Void

    private var tracedSet: Set<BoardCoordinate> {
        Set(tracedNodes.map { $0.coordinate })
    }

    var body: some View {
        let size = board.count
        VStack(alignment: .center, spacing: 6) {
            ForEach(0..<size, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<size, id: \.self) { column in
                        let coordinate = BoardCoordinate(row: row, column: column)
                        let tile = board[row][column]
                        TileView(
                            tile: tile,
                            isTraced: tracedSet.contains(coordinate),
                            isPlacementCandidate: placementCoordinate == coordinate
                        )
                        .onTapGesture {
                            onTap(coordinate, tile)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
        .animation(.easeInOut(duration: 0.15), value: tracedNodes)
    }
}

struct BoardView_Previews: PreviewProvider {
    static var previews: some View {
        let size = 5
        var board = Array(repeating: Array(repeating: TileState?.none, count: size), count: size)
        board[2][1] = TileState(letter: "A", isSeed: true)
        board[2][2] = TileState(letter: "D", isSeed: true)
        board[2][3] = TileState(letter: "D", isSeed: true)
        return BoardView(board: board, tracedNodes: [], placementCoordinate: nil) { _, _ in }
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
