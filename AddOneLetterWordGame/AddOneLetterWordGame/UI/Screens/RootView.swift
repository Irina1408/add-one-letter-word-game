import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        Group {
            switch appViewModel.dictionaryState {
            case .idle, .loading:
                loadingView
            case .failed(let message):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("Dictionary failed to load")
                        .font(.headline)
                    Text(message)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task { await appViewModel.environment.dictionaryService.loadIfNeeded() }
                    }
                }
                .padding()
            case .ready:
                MainTabView()
            }
        }
        .task {
            appViewModel.onAppear()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView("Preparing dictionary…")
                .progressViewStyle(.circular)
            Text("Indexing words for offline play")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

private struct MainTabView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var selection: AppViewModel.AppTab = .play

    var body: some View {
        TabView(selection: $selection) {
            GameRootView(environment: appViewModel.environment)
                .tabItem {
                    Label("Play", systemImage: "gamecontroller")
                }
                .tag(AppViewModel.AppTab.play)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(AppViewModel.AppTab.history)

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
                .tag(AppViewModel.AppTab.stats)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppViewModel.AppTab.settings)
        }
        .environmentObject(appViewModel)
    }
}

private struct GameRootView: View {
    let environment: AppEnvironment
    @StateObject private var viewModel: GameViewModel

    init(environment: AppEnvironment) {
        self.environment = environment
        _viewModel = StateObject(wrappedValue: GameViewModel(environment: environment))
    }

    var body: some View {
        GameView(viewModel: viewModel)
    }
}
