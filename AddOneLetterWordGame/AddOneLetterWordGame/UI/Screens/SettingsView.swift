import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Mode") {
                    Picker("Game Mode", selection: binding(for: \GameSettings.mode)) {
                        ForEach(GameMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    if appViewModel.settings.mode == .versusAI {
                        Picker("AI Difficulty", selection: binding(for: \GameSettings.aiDifficulty)) {
                            ForEach(AIDifficulty.allCases) { difficulty in
                                Text(difficulty.displayName).tag(difficulty)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section("Dictionary") {
                    Picker("Strictness", selection: binding(for: \GameSettings.dictionaryStrictness)) {
                        ForEach(DictionaryStrictness.allCases) { strictness in
                            Text(strictness.displayName).tag(strictness)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("Strict mode uses common words only; normal mode allows broader vocabulary.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Feedback") {
                    Toggle("Sound", isOn: binding(for: \GameSettings.soundEnabled))
                    Toggle("Haptics", isOn: binding(for: \GameSettings.hapticsEnabled))
                    Toggle("Hints", isOn: binding(for: \GameSettings.hintsEnabled))
                }

                Section("Learn & Support") {
                    NavigationLink(destination: TutorialView()) {
                        Label("Interactive Tutorial", systemImage: "hand.tap")
                    }
                    NavigationLink(destination: RulesView()) {
                        Label("Rules", systemImage: "list.bullet.rectangle")
                    }
                    Link(destination: URL(string: "mailto:support@addonelettergame.com")!) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Dictionary Size")
                        Spacer()
                        Text("≈130K words")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func binding<Value>(for keyPath: WritableKeyPath<GameSettings, Value>) -> Binding<Value> {
        Binding(
            get: { appViewModel.settings[keyPath: keyPath] },
            set: { newValue in appViewModel.updateSettings { $0[keyPath: keyPath] = newValue } }
        )
    }

    private var appVersion: String {
        let bundle = Bundle.main
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
