import Foundation
import Combine

final class DictionaryService: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading(Double)
        case ready
        case failed(String)
    }

    struct WordEntry: Equatable {
        let word: String
        let frequency: Double
    }

    @Published private(set) var loadState: LoadState = .idle

    private var index: DictionaryIndex?
    private let accessQueue = DispatchQueue(label: "com.addoneletter.dictionary.access", attributes: .concurrent)
    private let buildQueue = DispatchQueue(label: "com.addoneletter.dictionary.build", qos: .userInitiated)

    func loadIfNeeded(from bundle: Bundle = .main) async {
        let needsLoad = accessQueue.sync { index == nil }
        guard needsLoad else { return }
        await MainActor.run { [weak self] in
            self?.loadState = .loading(0)
        }

        await withCheckedContinuation { continuation in
            buildQueue.async { [weak self] in
                do {
                    let index = try DictionaryIndex.make(from: bundle)
                    self?.accessQueue.async(flags: .barrier) {
                        self?.index = index
                    }
                    Task { @MainActor in
                        self?.loadState = .ready
                        continuation.resume()
                    }
                } catch {
                    Task { @MainActor in
                        self?.loadState = .failed(error.localizedDescription)
                        continuation.resume()
                    }
                }
            }
        }
    }

    func contains(word: String, strictness: DictionaryStrictness) -> Bool {
        let lookup = accessQueue.sync { index }
        guard let lookup else { return false }
        return lookup.contains(word: word, minimumFrequency: strictness.minimumFrequency)
    }

    func hasPrefix(_ prefix: String) -> Bool {
        let lookup = accessQueue.sync { index }
        guard let lookup else { return false }
        return lookup.hasPrefix(prefix)
    }

    func frequency(of word: String) -> Double? {
        let lookup = accessQueue.sync { index }
        return lookup?.frequency(of: word)
    }

    func orderedLetters() -> [Character] {
        let lookup = accessQueue.sync { index }
        return lookup?.orderedLetters ?? Array("ETAOINSHRDLU" + "BCFGJKMPQVWXYZ")
    }

    func seedWords(for length: Int) -> [String] {
        let lookup = accessQueue.sync { index }
        return lookup?.seedWords[length] ?? []
    }

    func words(at length: Int, limit: Int, strictness: DictionaryStrictness) -> [WordEntry] {
        let lookup = accessQueue.sync { index }
        return lookup?.words(at: length, limit: limit, minimumFrequency: strictness.minimumFrequency) ?? []
    }
}

private final class DictionaryIndex {
    final class TrieNode {
        var children: [Character: TrieNode] = [:]
        var isWord: Bool = false
        var frequency: Double = 0
    }

    private let root: TrieNode
    private let wordMap: [String: Double]
    private let letterFrequency: [Character: Int]
    let orderedLetters: [Character]
    let seedWords: [Int: [String]]

    private init(root: TrieNode, wordMap: [String: Double], letterFrequency: [Character: Int], orderedLetters: [Character], seedWords: [Int: [String]]) {
        self.root = root
        self.wordMap = wordMap
        self.letterFrequency = letterFrequency
        self.orderedLetters = orderedLetters
        self.seedWords = seedWords
    }

    static func make(from bundle: Bundle) throws -> DictionaryIndex {
        guard let dictionaryURL = bundle.url(forResource: "english_words", withExtension: "tsv") else {
            throw NSError(domain: "Dictionary", code: 1, userInfo: [NSLocalizedDescriptionKey: "english_words.tsv missing from bundle"])
        }
        let data = try Data(contentsOf: dictionaryURL)
        guard let contents = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "Dictionary", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to decode dictionary data"])
        }

        let root = TrieNode()
        var map: [String: Double] = [:]
        var letterCounts: [Character: Int] = [:]

        func insert(word: String, frequency: Double) {
            var node = root
            for character in word {
                if node.children[character] == nil {
                    node.children[character] = TrieNode()
                }
                node = node.children[character]!
            }
            node.isWord = true
            node.frequency = frequency
        }

        contents.enumerateLines { line, _ in
            let parts = line.split(separator: "\t")
            guard parts.count == 2, let frequency = Double(parts[1]) else { return }
            let word = String(parts[0])
            map[word] = frequency
            insert(word: word, frequency: frequency)
            for character in word {
                letterCounts[character, default: 0] += 1
            }
        }

        let orderedLetters = letterCounts
            .sorted { lhs, rhs in lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value }
            .map { $0.key }

        var seedMap: [Int: [String]] = [:]
        for length in 4...7 {
            let resourceName = "seed_words_\(length)"
            if let url = bundle.url(forResource: resourceName, withExtension: "txt"),
               let seedContent = try? String(contentsOf: url) {
                let words = seedContent
                    .split(separator: "\n")
                    .map { String($0) }
                    .filter { !$0.isEmpty }
                seedMap[length] = words
            }
        }

        return DictionaryIndex(
            root: root,
            wordMap: map,
            letterFrequency: letterCounts,
            orderedLetters: orderedLetters,
            seedWords: seedMap
        )
    }

    private func node(for word: String) -> TrieNode? {
        var node = root
        for character in word {
            guard let next = node.children[character] else { return nil }
            node = next
        }
        return node
    }

    func contains(word: String, minimumFrequency: Double) -> Bool {
        guard let entry = node(for: word), entry.isWord else { return false }
        return entry.frequency >= minimumFrequency
    }

    func hasPrefix(_ prefix: String) -> Bool {
        node(for: prefix) != nil
    }

    func frequency(of word: String) -> Double? {
        wordMap[word]
    }

    func words(at length: Int, limit: Int, minimumFrequency: Double) -> [DictionaryService.WordEntry] {
        guard length > 0 else { return [] }
        var results: [DictionaryService.WordEntry] = []
        for (word, frequency) in wordMap where word.count == length && frequency >= minimumFrequency {
            results.append(.init(word: word, frequency: frequency))
        }
        return results
            .sorted { lhs, rhs in lhs.frequency == rhs.frequency ? lhs.word < rhs.word : lhs.frequency > rhs.frequency }
            .prefix(limit)
            .map { $0 }
    }
}
