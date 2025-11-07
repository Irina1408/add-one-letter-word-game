import CoreData
import Foundation

@MainActor
final class SettingsRepository: ObservableObject {
    @Published private(set) var settings: GameSettings

    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
        if let existing = SettingsRepository.fetchSettings(in: container.viewContext) {
            settings = SettingsRepository.makeSettings(from: existing)
        } else {
            settings = .default
            createDefaultSettings()
        }
    }

    func persist(_ update: (inout GameSettings) -> Void) {
        var mutable = settings
        update(&mutable)
        settings = mutable
        save(settings: mutable)
    }

    func reload() {
        if let existing = SettingsRepository.fetchSettings(in: container.viewContext) {
            settings = SettingsRepository.makeSettings(from: existing)
        }
    }

    private func createDefaultSettings() {
        let context = container.viewContext
        let entity = UserSettings(context: context)
        entity.id = "default"
        entity.aiDifficulty = settings.aiDifficulty.rawValue
        entity.boardSize = Int16(settings.boardSize)
        entity.dictionaryStrictness = settings.dictionaryStrictness.rawValue
        entity.mode = settings.mode.rawValue
        entity.hapticsEnabled = settings.hapticsEnabled
        entity.hintsEnabled = settings.hintsEnabled
        entity.soundEnabled = settings.soundEnabled
        saveContext()
    }

    private func save(settings: GameSettings) {
        let context = container.viewContext
        let entity = SettingsRepository.fetchSettings(in: context) ?? UserSettings(context: context)
        entity.id = "default"
        entity.aiDifficulty = settings.aiDifficulty.rawValue
        entity.boardSize = Int16(settings.boardSize)
        entity.dictionaryStrictness = settings.dictionaryStrictness.rawValue
        entity.mode = settings.mode.rawValue
        entity.hapticsEnabled = settings.hapticsEnabled
        entity.hintsEnabled = settings.hintsEnabled
        entity.soundEnabled = settings.soundEnabled
        saveContext()
    }

    private func saveContext() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Settings save error: \(error)")
        }
    }

    private static func fetchSettings(in context: NSManagedObjectContext) -> UserSettings? {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private static func makeSettings(from entity: UserSettings) -> GameSettings {
        GameSettings(
            boardSize: Int(entity.boardSize),
            mode: GameMode(rawValue: entity.mode) ?? .versusAI,
            aiDifficulty: AIDifficulty(rawValue: entity.aiDifficulty) ?? .medium,
            dictionaryStrictness: DictionaryStrictness(rawValue: entity.dictionaryStrictness) ?? .normal,
            soundEnabled: entity.soundEnabled,
            hapticsEnabled: entity.hapticsEnabled,
            hintsEnabled: entity.hintsEnabled
        )
    }
}
