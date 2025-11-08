import SwiftUI
import CoreData

@main
struct AddOneLetterWordGameApp: App {
    @StateObject private var appViewModel: AppViewModel
    private let environment: AppEnvironment

    init() {
        let environment = AppEnvironment.makeLive()
        self.environment = environment
        _appViewModel = StateObject(wrappedValue: AppViewModel(environment: environment))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appViewModel)
                .environment(\.managedObjectContext, environment.persistence.container.viewContext)
        }
    }
}
