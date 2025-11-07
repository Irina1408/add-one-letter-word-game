import SwiftUI

struct LetterPickerView: View {
    let onSelect: (Character) -> Void
    let onCancel: () -> Void

    private let letters: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        VStack(spacing: 16) {
            Text("Choose a letter")
                .font(.headline)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(letters, id: \.self) { letter in
                    Button(action: { onSelect(letter) }) {
                        Text(String(letter))
                            .font(.title2)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundColor(.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .accessibilityLabel("Letter \(letter)")
                }
            }
            Button("Cancel", action: onCancel)
                .font(.body.weight(.semibold))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(radius: 16)
        )
        .padding()
    }
}

struct LetterPickerView_Previews: PreviewProvider {
    static var previews: some View {
        LetterPickerView(onSelect: { _ in }, onCancel: {})
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
