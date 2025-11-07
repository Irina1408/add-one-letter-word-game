import CoreData
import Foundation

@objc(WordRecord)
public class WordRecord: NSManagedObject {}

extension WordRecord {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WordRecord> {
        NSFetchRequest<WordRecord>(entityName: "WordRecord")
    }

    @NSManaged public var player: String
    @NSManaged public var score: Int16
    @NSManaged public var text: String
    @NSManaged public var turnIndex: Int32
    @NSManaged public var match: MatchRecord
}
