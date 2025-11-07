import CoreData
import Foundation

@objc(TurnRecord)
public class TurnRecord: NSManagedObject {}

extension TurnRecord {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TurnRecord> {
        NSFetchRequest<TurnRecord>(entityName: "TurnRecord")
    }

    @NSManaged public var boardSnapshot: String?
    @NSManaged public var index: Int32
    @NSManaged public var player: String
    @NSManaged public var placementColumn: Int16
    @NSManaged public var placementRow: Int16
    @NSManaged public var placedLetter: String
    @NSManaged public var score: Int16
    @NSManaged public var timestamp: Date
    @NSManaged public var word: String
    @NSManaged public var match: MatchRecord
}

extension TurnRecord {
    var coordinate: BoardCoordinate {
        BoardCoordinate(row: Int(placementRow), column: Int(placementColumn))
    }
}
