import Combine
import Foundation

@MainActor
final class AppViewModel: ObservableObject {
    enum AppTab: Int, CaseIterable {
        case play
        case history
        case stats
        case settings
    }

    @Published private(set) var dictionaryState: DictionaryService.LoadState
    @Published var showTutorial: Bool
    @Published var settings: GameSettings
    @Published var activeTab: AppTab = .play

    let environment: AppEnvironment
    private var cancellables: Set<AnyCancellable> = []

    init(environment: AppEnvironment) {
        self.environment = environment
        self.dictionaryState = environment.dictionaryService.loadState
        self.settings = environment.settingsRepository.settings
        self.showTutorial = true

        environment.dictionaryService.$loadState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.dictionaryState = state
            }
            .store(in: &cancellables)

        environment.settingsRepository.$settings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.settings = settings
                self?.applyFeedbackSettings(settings)
            }
            .store(in: &cancellables)
        applyFeedbackSettings(settings)
    }

    func onAppear() {
        Task {
            await environment.dictionaryService.loadIfNeeded()
            environment.soundManager.preload()
        }
    }

    func updateSettings(_ update: (inout GameSettings) -> Void) {
        environment.settingsRepository.persist(update)
    }

    private func applyFeedbackSettings(_ settings: GameSettings) {
        environment.soundManager.isEnabled = settings.soundEnabled
        environment.hapticsManager.isEnabled = settings.hapticsEnabled
    }

    func setShowTutorial(_ show: Bool) {
        showTutorial = show
    }
}
