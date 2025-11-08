import SwiftUI

struct RulesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("How to Play")
                    .font(.title2.weight(.semibold))
                ruleBullet("Place exactly one letter on your turn. The letter must touch at least one existing tile horizontally or vertically.")
                ruleBullet("Trace a continuous word that uses the new letter. Tiles cannot be reused within the same word.")
                ruleBullet("Words must be unique for the match and found in the built-in dictionary.")
                ruleBullet("Scoring is simple: earn one point per letter in the word you submit.")
                ruleBullet("The game ends when no new words are possible or a player resigns. Highest total wins.")

                Text("Word Validity")
                    .font(.title3.weight(.semibold))
                ruleBullet("Proper nouns, abbreviations, contractions, and hyphenated terms are not allowed.")
                ruleBullet("Strict mode limits words to common vocabulary; normal mode permits a wider range.")

                Text("Accessibility & Etiquette")
                    .font(.title3.weight(.semibold))
                ruleBullet("Enable hints (one per turn) for gentle guidance.")
                ruleBullet("Sounds and haptics can be toggled from Settings.")
            }
            .padding()
        }
        .navigationTitle("Rules")
    }

    private func ruleBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle")
                .foregroundColor(.accentColor)
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.body)
    }
}
