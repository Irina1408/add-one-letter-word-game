import AVFoundation
import Foundation

final class SoundManager: NSObject {
    enum Sound: String, CaseIterable {
        case placeLetter
        case confirmWord
        case invalidAttempt
        case turnChange
        case gameEnd

        var filename: String {
            switch self {
            case .placeLetter: return "place_letter"
            case .confirmWord: return "confirm_word"
            case .invalidAttempt: return "invalid_attempt"
            case .turnChange: return "turn_change"
            case .gameEnd: return "game_end"
            }
        }
    }

    private var players: [Sound: AVAudioPlayer] = [:]
    var isEnabled: Bool = true

    func preload(from bundle: Bundle = .main) {
        Sound.allCases.forEach { sound in
            _ = player(for: sound, bundle: bundle)
        }
    }

    func play(_ sound: Sound) {
        guard isEnabled, let player = player(for: sound, bundle: .main) else { return }
        player.currentTime = 0
        player.play()
    }

    private func player(for sound: Sound, bundle: Bundle) -> AVAudioPlayer? {
        if let existing = players[sound] { return existing }
        guard let url = bundle.url(forResource: sound.filename, withExtension: "wav") else { return nil }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            players[sound] = player
            return player
        } catch {
            print("SoundManager error: \(error)")
            return nil
        }
    }
}
