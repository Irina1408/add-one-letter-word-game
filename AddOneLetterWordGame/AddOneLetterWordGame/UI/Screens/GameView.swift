import SwiftUI

struct GameView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @ObservedObject var viewModel: GameViewModel

    @State private var showNewGameSheet = false
    @State private var seedLength: Int = 5
    @State private var seedWord: String = ""

    private var dictionaryReady: Bool {
        if case .ready = appViewModel.dictionaryState { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 20) {
                        ScoreBarView(scores: viewModel.scores, currentPlayer: viewModel.currentPlayer)
                            .padding(.horizontal)
                        BoardView(
                            board: viewModel.boardSnapshot,
                            tracedNodes: viewModel.tracedNodes,
                            placementCoordinate: viewModel.placementCoordinate
                        ) { coordinate, tile in
                            handleBoardTap(coordinate: coordinate, tile: tile)
                        }
                        controlSection
                    }
                    .padding(.bottom, 40)
                }
                if let toast = viewModel.toastMessage {
                    VStack {
                        ToastView(message: toast)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        Spacer()
                    }
                    .padding(.top, 20)
                }
                if viewModel.isLetterPickerPresented {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                    LetterPickerView(onSelect: viewModel.chooseLetter) {
                        viewModel.isLetterPickerPresented = false
                    }
                }
                if viewModel.showPassAndPlayOverlay {
                    PassAndPlayOverlay(playerName: viewModel.currentPlayer.displayName) {
                        viewModel.dismissPassOverlay()
                    }
                }
                if viewModel.isProcessingTurn {
                    ProgressView("Thinking…")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
                        .shadow(radius: 12)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showNewGameSheet = true }) {
                        Label("New Game", systemImage: "play.circle")
                    }
                    .disabled(!dictionaryReady)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.removeLastTraceNode) {
                        Label("Undo", systemImage: "arrow.uturn.left")
                    }
                    .disabled(viewModel.tracedNodes.isEmpty)
                }
            }
            .navigationTitle("Add-one-letter")
            .sheet(isPresented: $showNewGameSheet, onDismiss: resetSeedDefaults) {
                NewGameSheet(
                    settings: appViewModel.settings,
                    seedLength: $seedLength,
                    seedWord: $seedWord,
                    dictionaryService: appViewModel.environment.dictionaryService,
                    onStart: startNewGame
                )
                .presentationDetents([.fraction(0.6), .large])
            }
            .onAppear {
                resetSeedDefaults()
                if dictionaryReady, case .idle = viewModel.phase {
                    viewModel.startNewGame(seedWord: viewModel.makeRandomSeedWord(length: appViewModel.settings.boardSize))
                }
            }
            .onChange(of: appViewModel.dictionaryState) { newValue in
                if case .ready = newValue, case .idle = viewModel.phase {
                    viewModel.startNewGame(seedWord: viewModel.makeRandomSeedWord(length: appViewModel.settings.boardSize))
                }
            }
            .onChange(of: viewModel.toastMessage) { _ in
                dismissToastAfterDelay()
            }
        }
    }

    private var controlSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: viewModel.requestHint) {
                    Label("Hint", systemImage: "lightbulb")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle(enabled: appViewModel.settings.hintsEnabled))
                .disabled(!appViewModel.settings.hintsEnabled)

                Button(action: viewModel.submitWord) {
                    Label("Submit", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle(enabled: viewModel.canSubmitWord))
                .disabled(!viewModel.canSubmitWord)
            }

            if let hint = viewModel.hintSuggestion {
                HintCardView(hint: hint)
            }
        }
        .padding(.horizontal)
    }

    private func handleBoardTap(coordinate: BoardCoordinate, tile: TileState?) {
        switch viewModel.phase {
        case .awaitingPlacement:
            if tile == nil {
                viewModel.selectPlacement(at: coordinate)
            }
        case .tracing:
            viewModel.appendTrace(at: coordinate)
        case .choosingLetter:
            break
        case .aiProcessing, .idle, .gameOver:
            break
        }
    }

    private func resetSeedDefaults() {
        seedLength = appViewModel.settings.boardSize
        seedWord = viewModel.makeRandomSeedWord(length: seedLength)
    }

    private func startNewGame() {
        appViewModel.updateSettings { settings in
            settings.boardSize = seedLength
        }
        showNewGameSheet = false
        viewModel.startNewGame(seedWord: seedWord)
    }

    private func dismissToastAfterDelay() {
        guard viewModel.toastMessage != nil else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation {
                viewModel.toastMessage = nil
            }
        }
    }
}

private struct HintCardView: View {
    let hint: HintSuggestion

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
            VStack(alignment: .leading, spacing: 4) {
                Text(hint.message)
                    .font(.body)
                Text("Suggested letter: \(hint.letter) — candidate word \(hint.word)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(hint.message)
    }
}

private struct PassAndPlayOverlay: View {
    let playerName: String
    let onContinue: () -> Void

    var body: some View {
        Color.black.opacity(0.65)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 16) {
                    Text("Pass to \(playerName)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Hand the device to the next player.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.8))
                    Button(action: onContinue) {
                        Text("Ready")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color.white))
                    }
                    .accessibilityLabel("Continue for \(playerName)")
                }
                .padding()
            )
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    let enabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(enabled ? Color.accentColor : Color.gray.opacity(0.3))
            )
            .foregroundColor(enabled ? .white : .secondary)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

private struct NewGameSheet: View {
    let settings: GameSettings
    @Binding var seedLength: Int
    @Binding var seedWord: String
    let dictionaryService: DictionaryService
    let onStart: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var seeds: [String] {
        dictionaryService.seedWords(for: seedLength).prefix(40).map { $0.uppercased() }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Board Size") {
                    Picker("Letters", selection: $seedLength) {
                        ForEach(settings.seedLengthRange, id: \.self) { length in
                            Text("\(length) letters").tag(length)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Seed Word") {
                    Picker("Seed", selection: $seedWord) {
                        ForEach(seeds, id: \.self) { word in
                            Text(word).tag(word)
                        }
                    }
                    .pickerStyle(.wheel)
                    Button("Randomize") {
                        if let random = seeds.randomElement() {
                            seedWord = random
                        }
                    }
                }

                Section {
                    Button("Start Match") {
                        onStart()
                        dismiss()
                    }
                    .disabled(seedWord.isEmpty)
                }
            }
            .navigationTitle("New Game")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if seedWord.isEmpty {
                    seedWord = seeds.first ?? ""
                }
            }
        }
    }
}
