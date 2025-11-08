import Foundation

struct AppEnvironment {
    let dictionaryService: DictionaryService
    let persistence: PersistenceController
    let matchRepository: MatchRepository
    let settingsRepository: SettingsRepository
    let soundManager: SoundManager
    let hapticsManager: HapticsManager
    let hintService: HintService

    @MainActor
    static func makeLive() -> AppEnvironment {
        let persistence = PersistenceController.shared
        let dictionary = DictionaryService()
        let sound = SoundManager()
        let haptics = HapticsManager.shared
        let matchRepository = MatchRepository(container: persistence.container)
        let settingsRepository = SettingsRepository(container: persistence.container)
        let hintService = HintService()
        return AppEnvironment(
            dictionaryService: dictionary,
            persistence: persistence,
            matchRepository: matchRepository,
            settingsRepository: settingsRepository,
            soundManager: sound,
            hapticsManager: haptics,
            hintService: hintService
        )
    }
}
