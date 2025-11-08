import CoreData
import Foundation

@objc(MatchRecord)
public class MatchRecord: NSManagedObject {}

extension MatchRecord {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MatchRecord> {
        NSFetchRequest<MatchRecord>(entityName: "MatchRecord")
    }

    @NSManaged public var aiDifficulty: String?
    @NSManaged public var boardSize: Int16
    @NSManaged public var date: Date
    @NSManaged public var duration: Double
    @NSManaged public var id: UUID
    @NSManaged public var mode: String
    @NSManaged public var playerOneScore: Int32
    @NSManaged public var playerTwoScore: Int32
    @NSManaged public var seedWord: String
    @NSManaged public var turnCount: Int32
    @NSManaged public var winner: String?
    @NSManaged public var longestWord: String?
    @NSManaged public var turns: NSSet?
    @NSManaged public var words: NSSet?
}

extension MatchRecord {
    @objc(addTurnsObject:)
    @NSManaged public func addToTurns(_ value: TurnRecord)

    @objc(removeTurnsObject:)
    @NSManaged public func removeFromTurns(_ value: TurnRecord)

    @objc(addTurns:)
    @NSManaged public func addToTurns(_ values: NSSet)

    @objc(removeTurns:)
    @NSManaged public func removeFromTurns(_ values: NSSet)

    @objc(addWordsObject:)
    @NSManaged public func addToWords(_ value: WordRecord)

    @objc(removeWordsObject:)
    @NSManaged public func removeFromWords(_ value: WordRecord)

    @objc(addWords:)
    @NSManaged public func addToWords(_ values: NSSet)

    @objc(removeWords:)
    @NSManaged public func removeFromWords(_ values: NSSet)
}

extension MatchRecord {
    var sortedTurns: [TurnRecord] {
        let set = turns as? Set<TurnRecord> ?? []
        return set.sorted { $0.index < $1.index }
    }

    var sortedWords: [WordRecord] {
        let set = words as? Set<WordRecord> ?? []
        return set.sorted { $0.turnIndex < $1.turnIndex }
    }
}
