import SwiftUI

struct TileView: View {
    let tile: TileState?
    let isTraced: Bool
    let isPlacementCandidate: Bool

    private var borderColor: Color {
        if isTraced { return Color.accentColor }
        if tile != nil { return Color.primary.opacity(0.2) }
        return Color.primary.opacity(0.1)
    }

    private var backgroundColor: Color {
        if isTraced { return Color.accentColor.opacity(0.2) }
        if tile?.isSeed == true { return Color.blue.opacity(0.15) }
        if tile != nil { return Color.primary.opacity(0.05) }
        return Color(.systemBackground).opacity(0.6)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(borderColor, style: StrokeStyle(lineWidth: isPlacementCandidate ? 3 : 1.5, dash: tile == nil ? [4] : []))
                )
            if let tile {
                Text(String(tile.letter))
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .accessibilityHidden(true)
            } else if isPlacementCandidate {
                Image(systemName: "plus")
                    .foregroundColor(Color.accentColor)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if let tile {
            return tile.isSeed ? "Seed letter \(tile.letter)" : "Letter \(tile.letter)"
        }
        return isPlacementCandidate ? "Empty cell, tap to place a letter" : "Empty cell"
    }
}

struct TileView_Previews: PreviewProvider {
    static var previews: some View {
        TileView(tile: TileState(letter: "A", isSeed: true), isTraced: false, isPlacementCandidate: false)
            .frame(width: 60, height: 60)
            .padding()
    }
}
