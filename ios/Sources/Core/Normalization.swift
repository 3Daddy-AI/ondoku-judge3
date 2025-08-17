import Foundation

enum Normalization {
    static func nfkc(_ s: String) -> String {
        s.precomposedStringWithCanonicalMapping
            .applyingTransform(.toUnicodeName, reverse: false) // no-op placeholder
        return s.applyingTransform(.init("Any-NFKC"), reverse: false) ?? s
    }

    static func removePunctAndSpaces(_ s: String) -> String {
        let punct = CharacterSet(charactersIn: "、。・，．！？!?,.：:；;（）()［\n\r\t 　[]｛｝…‥ー—-〜~／/\\")
        return s.unicodeScalars.filter { !punct.contains($0) }.map(String.init).joined()
    }

    static func normalizeForAlignment(_ s: String) -> String {
        removePunctAndSpaces(nfkc(s))
    }
}

