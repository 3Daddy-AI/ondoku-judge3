import Foundation

struct AlignmentOp {
    enum Kind { case equal, replace, insert, delete }
    let kind: Kind
    let ref: Character?
    let hyp: Character?
}

struct AlignmentResult {
    let ops: [AlignmentOp]
    let cer: Double
    let errors: Int
    let refLen: Int
}

enum Aligner {
    static func levenshtein(ref: String, hyp: String) -> AlignmentResult {
        let r = Array(ref)
        let h = Array(hyp)
        let n = r.count, m = h.count
        var dp = Array(repeating: Array(repeating: 0, count: m+1), count: n+1)
        var bt = Array(repeating: Array(repeating: (0,0), count: m+1), count: n+1)
        for i in 1...n { dp[i][0] = i; bt[i][0] = (i-1,0) }
        for j in 1...m { dp[0][j] = j; bt[0][j] = (0,j-1) }
        if n > 0 && m > 0 {
            for i in 1...n {
                for j in 1...m {
                    let cost = (r[i-1] == h[j-1]) ? 0 : 1
                    let del = dp[i-1][j] + 1
                    let ins = dp[i][j-1] + 1
                    let sub = dp[i-1][j-1] + cost
                    let best = min(del, ins, sub)
                    dp[i][j] = best
                    if best == sub { bt[i][j] = (i-1, j-1) }
                    else if best == del { bt[i][j] = (i-1, j) }
                    else { bt[i][j] = (i, j-1) }
                }
            }
        }
        var ops: [AlignmentOp] = []
        var i = n, j = m
        while !(i == 0 && j == 0) {
            let (pi, pj) = bt[i][j]
            if pi == i-1 && pj == j-1 {
                let rc = r[i-1]; let hc = h[j-1]
                if rc == hc { ops.append(.init(kind: .equal, ref: rc, hyp: hc)) }
                else { ops.append(.init(kind: .replace, ref: rc, hyp: hc)) }
            } else if pi == i-1 && pj == j { ops.append(.init(kind: .delete, ref: r[i-1], hyp: nil)) }
            else { ops.append(.init(kind: .insert, ref: nil, hyp: h[j-1])) }
            i = pi; j = pj
        }
        ops.reverse()
        let errors = ops.reduce(0) { $0 + (([$1.kind] as [AlignmentOp.Kind]).contains(.replace) || $1.kind == .insert || $1.kind == .delete ? 1 : 0) }
        let cer = n > 0 ? Double(errors) / Double(n) : 0.0
        return .init(ops: ops, cer: cer, errors: errors, refLen: n)
    }

    static func preview(_ ops: [AlignmentOp]) -> String {
        var s = ""
        for o in ops {
            switch o.kind {
            case .equal: s.append(o.ref!)
            case .replace: s.append("[\(o.ref!)->\(o.hyp!)]")
            case .insert: s.append("(+\(o.hyp!))")
            case .delete: s.append("(-\(o.ref!))")
            }
        }
        return s
    }
}

