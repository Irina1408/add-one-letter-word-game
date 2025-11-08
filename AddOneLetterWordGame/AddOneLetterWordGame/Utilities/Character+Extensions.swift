import Foundation

extension Character {
    var uppercasedCharacter: Character {
        Character(String(self).uppercased())
    }

    var lowercasedCharacter: Character {
        Character(String(self).lowercased())
    }

    var lowercasedString: String {
        String(self).lowercased()
    }
}
