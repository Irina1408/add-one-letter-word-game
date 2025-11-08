import CoreData
import Foundation

@objc(UserSettings)
public class UserSettings: NSManagedObject {}

extension UserSettings {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserSettings> {
        NSFetchRequest<UserSettings>(entityName: "UserSettings")
    }

    @NSManaged public var aiDifficulty: String
    @NSManaged public var boardSize: Int16
    @NSManaged public var dictionaryStrictness: String
    @NSManaged public var mode: String
    @NSManaged public var hapticsEnabled: Bool
    @NSManaged public var hintsEnabled: Bool
    @NSManaged public var soundEnabled: Bool
    @NSManaged public var id: String
}
