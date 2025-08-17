import SwiftUI

struct DiffChunk: Identifiable { let id = UUID(); let text: String; let color: Color }

struct DiffTextView: View {
    let preview: String
    var body: some View {
        // 簡易: [a->b] をオレンジ, (+x) を青, (-y) を赤、それ以外は黒
        let chunks = parse(preview)
        return HStack(alignment: .top, spacing: 0) {
            ForEach(chunks) { c in
                Text(c.text).foregroundColor(c.color)
            }
        }
    }

    private func parse(_ s: String) -> [DiffChunk] {
        var res: [DiffChunk] = []
        var i = s.startIndex
        while i < s.endIndex {
            let ch = s[i]
            if ch == "[" {
                if let r = s[i...].firstIndex(of: "]") {
                    let inner = String(s[s.index(after: i)..<r])
                    res.append(.init(text: "[" + inner + "]", color: .orange))
                    i = s.index(after: r)
                    continue
                }
            } else if ch == "(" {
                if let r = s[i...].firstIndex(of: ")") {
                    let inner = String(s[s.index(after: i)..<r])
                    let color: Color = inner.hasPrefix("+") ? .blue : .red
                    res.append(.init(text: "(" + inner + ")", color: color))
                    i = s.index(after: r)
                    continue
                }
            }
            res.append(.init(text: String(ch), color: .primary))
            i = s.index(after: i)
        }
        return res
    }
}

