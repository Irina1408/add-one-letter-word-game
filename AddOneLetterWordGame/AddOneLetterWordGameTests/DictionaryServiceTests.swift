import XCTest
@testable import AddOneLetterWordGame

final class DictionaryServiceTests: XCTestCase {
    func testContainsAndPrefixLookup() async throws {
        let service = DictionaryService()
        await service.loadIfNeeded(from: resourceBundle)

        XCTAssertTrue(service.contains(word: "bread", strictness: .normal))
        XCTAssertTrue(service.hasPrefix("bre"))
        XCTAssertFalse(service.contains(word: "zzzzz", strictness: .strict))
    }

    func testSeedWordsAvailable() async throws {
        let service = DictionaryService()
        await service.loadIfNeeded(from: resourceBundle)
        let seeds = service.seedWords(for: 5)
        XCTAssertFalse(seeds.isEmpty)
    }

    private var resourceBundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: DictionaryServiceTests.self)
        #endif
    }
}
