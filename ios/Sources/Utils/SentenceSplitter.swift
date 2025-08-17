import Foundation

enum SentenceSplitter {
    static func split(_ text: String) -> [String] {
        let separators = CharacterSet(charactersIn: "。！？\n")
        var parts: [String] = []
        var current = ""
        for ch in text {
            current.append(ch)
            if String(ch).rangeOfCharacter(from: separators) != nil {
                let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { parts.append(trimmed) }
                current.removeAll(keepingCapacity: true)
            }
        }
        let t = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { parts.append(t) }
        return parts
    }
}

