import Combine
import Foundation

@MainActor
final class GameViewModel: ObservableObject {
    enum Phase {
        case idle
        case awaitingPlacement
        case choosingLetter(BoardCoordinate)
        case tracing(BoardCoordinate, Character)
        case aiProcessing
        case gameOver(GameSummary)
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var boardSnapshot: [[TileState?]] = []
    @Published private(set) var currentPlayer: PlayerKind = .human(name: "Player 1")
    @Published private(set) var scores: [PlayerKind: Int] = [:]
    @Published private(set) var usedWords: [String] = []
    @Published private(set) var hintSuggestion: HintSuggestion?
    @Published private(set) var summary: GameSummary?
    @Published var tracedNodes: [WordPath.Node] = []
    @Published var toastMessage: String?
    @Published var isLetterPickerPresented: Bool = false
    @Published var selectedLetter: Character?
    @Published var placementCoordinate: BoardCoordinate?
    @Published var isProcessingTurn: Bool = false
    @Published var showPassAndPlayOverlay: Bool = false

    var canSubmitWord: Bool {
        tracedNodes.count >= 3 && placementCoordinate != nil && tracedNodes.contains(where: { $0.coordinate == placementCoordinate })
    }

    private let environment: AppEnvironment
    private var engine: GameEngine?
    private var aiPlayer: AIPlayer?
    private var hintsUsedThisTurn = 0

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    func startNewGame(seedWord: String? = nil) {
        Task { await makeNewGame(seedWord: seedWord) }
    }

    func makeRandomSeedWord(length: Int) -> String {
        environment.dictionaryService.seedWords(for: length).randomElement()?.uppercased() ?? "GAME"
    }

    func selectPlacement(at coordinate: BoardCoordinate) {
        guard case .awaitingPlacement = phase else { return }
        Task {
            guard let engine, await engine.canPlace(at: coordinate) else {
                environment.hapticsManager.warning()
                environment.soundManager.play(.invalidAttempt)
                toastMessage = "You must place letters next to existing tiles."
                return
            }
            placementCoordinate = coordinate
            selectedLetter = nil
            tracedNodes = []
            isLetterPickerPresented = true
            phase = .choosingLetter(coordinate)
        }
    }

    func chooseLetter(_ letter: Character) {
        guard case let .choosingLetter(coordinate) = phase else { return }
        let uppercaseLetter = Character(String(letter).uppercased())
        selectedLetter = uppercaseLetter
        placementCoordinate = coordinate
        tracedNodes = []
        isLetterPickerPresented = false
        phase = .tracing(coordinate, uppercaseLetter)
        environment.soundManager.play(.placeLetter)
        environment.hapticsManager.impact(.light)
    }

    func appendTrace(at coordinate: BoardCoordinate) {
        guard case let .tracing(_, letter) = phase else { return }
        guard let engine else { return }
        guard tracedNodes.allSatisfy({ $0.coordinate != coordinate }) else { return }
        Task {
            let state = await engine.state()
            if tracedNodes.isEmpty {
                if let node = makeNode(for: coordinate, in: state, selectedLetter: letter) {
                    tracedNodes = [node]
                }
                return
            }
            if let last = tracedNodes.last {
                let boardSize = state.board.size
                guard last.coordinate.neighbors(within: boardSize).contains(coordinate) else {
                    environment.hapticsManager.warning()
                    toastMessage = "Tiles must be adjacent."
                    return
                }
            }
            if let node = makeNode(for: coordinate, in: state, selectedLetter: letter) {
                tracedNodes.append(node)
            }
        }
    }

    private func makeNode(for coordinate: BoardCoordinate, in state: GameState, selectedLetter: Character) -> WordPath.Node? {
        if coordinate == placementCoordinate {
            return WordPath.Node(coordinate: coordinate, letter: selectedLetter)
        }
        if let tile = state.board[coordinate] {
            return WordPath.Node(coordinate: coordinate, letter: tile.letter)
        }
        return nil
    }

    func removeLastTraceNode() {
        guard case .tracing = phase, !tracedNodes.isEmpty else { return }
        tracedNodes.removeLast()
    }

    func requestHint() {
        guard hintsUsedThisTurn == 0 else { return }
        guard environment.settingsRepository.settings.hintsEnabled else { return }
        guard let engine else { return }
        hintsUsedThisTurn += 1
        Task {
            hintSuggestion = await environment.hintService.makeHint(from: engine)
            if hintSuggestion != nil {
                environment.hapticsManager.impact(.light)
            }
        }
    }

    func submitWord() {
        guard let engine, let coordinate = placementCoordinate, let letter = selectedLetter else { return }
        guard canSubmitWord else {
            environment.hapticsManager.warning()
            environment.soundManager.play(.invalidAttempt)
            toastMessage = "Finish tracing your word first."
            return
        }
        Task {
            do {
                isProcessingTurn = true
                let path = WordPath(nodes: tracedNodes)
                let move = GameMove(coordinate: coordinate, letter: letter, wordPath: path)
                let outcome = try await engine.apply(move: move)
                await handleTurnOutcome(outcome)
            } catch let error as WordValidationError {
                toastMessage = error.localizedDescription
                environment.hapticsManager.warning()
                environment.soundManager.play(.invalidAttempt)
                isProcessingTurn = false
            } catch {
                toastMessage = "Could not complete the move."
                environment.soundManager.play(.invalidAttempt)
                isProcessingTurn = false
            }
        }
    }

    private func makeNewGame(seedWord: String?) async {
        hintsUsedThisTurn = 0
        isProcessingTurn = true
        showPassAndPlayOverlay = false
        summary = nil
        hintSuggestion = nil
        let settings = environment.settingsRepository.settings
        let players: [PlayerKind]
        if settings.mode == .versusAI {
            players = [.human(name: "You"), .computer(name: "Lexi", difficulty: settings.aiDifficulty)]
        } else {
            players = [.human(name: "Player 1"), .human(name: "Player 2")]
        }
        let seed = seedWord ?? makeRandomSeedWord(length: settings.boardSize)
        do {
            let engine = try GameEngine(settings: settings, seedWord: seed, players: players, dictionary: environment.dictionaryService)
            self.engine = engine
            aiPlayer = settings.mode == .versusAI ? aiPlayer(for: settings.aiDifficulty) : nil
            await refreshState()
            phase = .awaitingPlacement
            isProcessingTurn = false
            if players.first?.isComputer == true {
                await performAIMove()
            }
        } catch {
            toastMessage = error.localizedDescription
            isProcessingTurn = false
        }
    }

    private func refreshState() async {
        guard let engine else { return }
        let state = await engine.state()
        boardSnapshot = state.board.tiles
        currentPlayer = state.currentPlayer
        scores = state.scores
        usedWords = Array(state.usedWords).map { $0.uppercased() }.sorted()
    }

    private func handleTurnOutcome(_ outcome: GameTurnOutcome) async {
        guard let engine else { return }
        environment.soundManager.play(.confirmWord)
        environment.hapticsManager.success()
        placementCoordinate = nil
        selectedLetter = nil
        tracedNodes = []
        hintSuggestion = nil
        await refreshState()
        isProcessingTurn = false
        if outcome.isGameOver {
            environment.soundManager.play(.gameEnd)
            environment.hapticsManager.success()
            summary = await engine.summary()
            showPassAndPlayOverlay = false
            if let summary {
                phase = .gameOver(summary)
            }
        } else {
            environment.soundManager.play(.turnChange)
            hintsUsedThisTurn = 0
            let isPassAndPlay = environment.settingsRepository.settings.mode == .passAndPlay
            showPassAndPlayOverlay = isPassAndPlay
            phase = .awaitingPlacement
            if currentPlayer.isComputer, aiPlayer != nil {
                await performAIMove()
            }
        }
    }

    private func performAIMove() async {
        guard let engine, let aiPlayer else { return }
        phase = .aiProcessing
        isProcessingTurn = true
        let settings = environment.settingsRepository.settings
        let candidate = await aiPlayer.chooseMove(using: engine, settings: settings)
        guard let candidate else {
            phase = .awaitingPlacement
            isProcessingTurn = false
            return
        }
        do {
            let outcome = try await engine.apply(move: candidate.move)
            await handleTurnOutcome(outcome)
        } catch {
            toastMessage = "AI failed to play a move."
            isProcessingTurn = false
        }
    }

    private func aiPlayer(for difficulty: AIDifficulty) -> AIPlayer {
        switch difficulty {
        case .easy: return EasyAIPlayer()
        case .medium: return MediumAIPlayer()
        case .hard: return HardAIPlayer()
        }
    }
    func dismissPassOverlay() {
        showPassAndPlayOverlay = false
    }

}
